library(pomp)
library(reshape2)
library(plyr)
library(magrittr)
library(ggplot2)
library(mvtnorm)
set.seed(1638125322)

png(filename="kalman-%02d.png",res=100)

t <- seq(1,100)

C <- matrix(c(1, 0,  0, 0,
              0, 1, -1, 0),
            2,4,byrow=TRUE)

dimX <- ncol(C)
dimY <- nrow(C)

dimnames(C) <- list(
    paste0("y",seq_len(dimY)),
    paste0("x",seq_len(dimX)))

R <- matrix(c(1, 0.3,
              0.3, 1),
            nrow=dimY,
            dimnames=list(rownames(C),rownames(C)))

A <- matrix(c(-0.677822, -0.169411,  0.420662,  0.523571,
               2.87451,  -0.323604, -0.489533, -0.806087,
              -1.36617,  -0.592326,  0.567114,  0.345142,
              -0.807978, -0.163305,  0.668037,  0.468286),
            nrow=dimX,ncol=dimX,byrow=TRUE,
            dimnames=list(colnames(C),colnames(C)))

Q <- crossprod(matrix(rnorm(n=dimX*dimX,sd=1/4),4,4))
dimnames(Q) <- dimnames(A)

X0 <- setNames(rnorm(dimX),colnames(C))

N <- length(t)
x <- array(dim=c(dimX,N),dimnames=list(variable=colnames(C),time=t))
y <- array(dim=c(dimY,N),dimnames=list(variable=rownames(C),time=t))

xx <- X0
sqrtQ <- t(chol(Q))
sqrtR <- t(chol(R))
for (k in seq_along(t)) {
    x[,k] <- xx <- A %*% xx + sqrtQ %*% rnorm(n=dimX)
    y[,k] <- C %*% xx + sqrtR %*% rnorm(n=dimY)
}

kf <- pomp:::kalmanFilter(t,y,X0,A,Q,C,R)

y %>% melt() %>% dcast(time~variable) %>%
  pomp(times='time',t0=0,
       rprocess=discrete.time.sim(
         step.fun=function(x,t,params,delta.t,...){
           A%*%x+sqrtQ%*%rnorm(n=ncol(A))
         },
         delta.t=1),
       rmeasure=function(x,t,params,...){
         C%*%x+sqrtR%*%rnorm(n=nrow(C))
       },
       dmeasure=function(y,x,t,params,log,...){
         dmvnorm(x=t(y-C%*%x),sigma=R,log=log)
       },
       initializer=function(params,t0,...){
         X0
       },
       params=c(dummy=3)) %>%
  pfilter(Np=1000,filter.mean=TRUE) -> pf

enkf <- enkf(pf,h=function(x)C%*%x,R=R,Np=1000)
eakf <- eakf(pf,C=C,R=R,Np=1000)

invisible(enkf(pf,h=function(x)C%*%x,R=R,Np=1000,params=as.list(coef(pf))))
invisible(eakf(pf,C=C,R=R,Np=1000,params=as.list(coef(pf))))

stopifnot(max(abs(c(kf$loglik,logLik(pf),logLik(enkf),logLik(eakf))-c(-391.0,-391.6,-390.5,-390.8)))<1)

enkf %>% as.data.frame() %>% melt(id.vars="time") %>%
    ddply(~variable,summarize,n=length(value))
eakf %>% as.data.frame() %>% melt(id.vars="time") %>%
    ddply(~variable,summarize,n=length(value))

enkf$forecast %>% melt() %>%
    ggplot(aes(x=time,y=value,group=variable,color=variable))+
    geom_line()+theme_bw()

identical(eakf$cond.loglik,cond.logLik(eakf))
identical(enkf$pred.mean,pred.mean(enkf))
identical(eakf$filter.mean,filter.mean(eakf))

try({
    R <- matrix(c(1,0,1,0),2,2)
    enkf(pf,h=function(x)C%*%x,Np=1000,R=R)
})

try({
    ev <- eigen(R)
    eakf(pf,C=C,Np=1000,R=R)
})

dev.off()
