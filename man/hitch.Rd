\name{hitch}
\docType{methods}
\title{Hitching C snippets and R functions to pomp.fun objects}
\alias{hitch}
\description{
  The algorithms in \pkg{pomp} make use of user-defined functions implementing the various elementary model computations (\code{rprocess}, \code{dprocess}, \code{rmeasure}, \code{dmeasure}, etc.).
  For short, we refer to these elementary computations as \dQuote{workhorses}.
  The user defines these functions using \R functions, links to native functions in dynamically-linked libraries, or C snippets.
  For efficiency, \pkg{pomp} encodes the workhorses using \code{pomp.fun} objects.
  The construction of \code{pomp.fun} objects is handled by the \code{hitch} function, which conceptually \dQuote{hitches} the workhorses to \code{pomp.fun}s for use in \pkg{pomp}.
}
\usage{
hitch(\dots, templates,
      obsnames, statenames, paramnames, covarnames,
      PACKAGE, globals, cfile, cdir, shlib.args,
      verbose = getOption("verbose", FALSE))
}
\arguments{
 \item{\dots}{
    named arguments representing the workhorses.
    These can be \R functions, character strings naming routines in external, dynamically-linked libraries, C snippets, or \code{NULL}.
    The first three are converted by \code{hitch} to \code{pomp.fun} objects which perform the indicated computations.
    \code{NULL} arguments are translated to default \code{pomp.fun} objects, which trigger an error when they are asked to perform a computation.
  }
  \item{templates}{
    named list of templates.
    Each workhorse must have a corresponding template.
    See \code{pomp:::workhorse_templates} for a list.
  }
  \item{obsnames, statenames, paramnames, covarnames}{
    character vectors specifying the names of observable variables, latent state variables, parameters, and covariates, respectively.
    These are only needed if one or more of the horses are furnished as C snippets.
  }
  \item{PACKAGE}{
    If one or more of the horses is specified as the name of a function in an external library, the library (without file extension) should be named here.
  }
  \item{globals}{
    optional character;
    C code that will be included in the source for (and therefore hard-coded into) the shared-object library created when the call to \code{pomp} uses C snippets.
    If no C snippets are used, \code{globals} has no effect.
  }
  \item{cdir, cfile, shlib.args}{
    optional character variables.
    \code{cdir} specifies the name of the directory within which C snippet code will be compiled.
    By default, this is in a temporary directory specific to the running instance of \R.
    \code{cfile} gives the name of the file (in directory \code{cdir}) into which C snippet codes will be written.
    By default, a random filename is used.
    The \code{shlib.args} can be used to pass command-line arguments to the \code{R CMD SHLIB} call that will compile the C snippets.
  }
  \item{verbose}{
    logical.
    Setting \code{verbose=TRUE} will cause additional information to be displayed.
  }
}
\value{
  \code{hitch} returns a named list of length two.
  The element named \dQuote{funs} is itself a named list of \code{pomp.fun} objects, each of which corresponds to one of the horses passed in.
  The element named \dQuote{lib} contains information on the shared-object library created using the C snippets (if any were passed to \code{hitch}).
  If no C snippets were passed to \code{hitch}, \code{lib} is \code{NULL}.
  Otherwise, it is a length-3 named list with the following elements:
  \describe{
    \item{name}{The name of the library created.}
    \item{dir}{
      The directory in which the library was created.
      If this is \code{NULL}, the library was created in the \R session's temporary directory.
    }
    \item{src}{
      A character string with the full contents of the C snippet file.
    }
  }
}
\author{Aaron A. King}
\seealso{\code{\link{pomp}}, \code{\link{spy}}}
\keyword{programming}
