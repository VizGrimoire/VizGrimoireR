\name{TimeSeriesYears-class}
\Rdversion{1.1}
\docType{class}
\alias{TimeSeriesYears-class}
\alias{initialize,TimeSeriesYears-method}
\alias{JSON,TimeSeriesYears-method}
\alias{Plot,TimeSeriesYears-method}

\title{Class \code{"TimeSeriesYears"}}
\description{
%%  ~~ A concise (1-5 lines) description of what the class is. ~~
}
\section{Objects from the Class}{
Objects can be created by calls of the form \code{new("TimeSeriesYears", data, columns, labels)}.
%%  ~~ describe objects here ~~ 
}
\section{Slots}{
  \describe{
    \item{\code{.Data}:}{Object of class \code{"vector"} ~~ }
    \item{\code{labels}:}{Object of class \code{"vector"} ~~ }
    \item{\code{tsp}:}{Object of class \code{"numeric"} ~~ }
    \item{\code{.S3Class}:}{Object of class \code{"character"} ~~ }
  }
}
\section{Extends}{
Class \code{"\linkS4class{ts}"}, directly.
Class \code{"\linkS4class{structure}"}, by class "ts", distance 2.
Class \code{"\linkS4class{oldClass}"}, by class "ts", distance 2.
Class \code{"\linkS4class{vector}"}, by class "ts", distance 3, with explicit coerce.
}
\section{Methods}{
  \describe{
    \item{initialize}{\code{signature(.Object = "TimeSeriesYears")}: ... }
    \item{JSON}{\code{signature(.Object = "TimeSeriesYears")}: ... }
    \item{Plot}{\code{signature(.Object = "TimeSeriesYears")}: ... }
	 }
}
\references{
%%  ~~put references to the literature/web site here~~
}
\author{
%%  ~~who you are~~
}
\note{
%%  ~~further notes~~
}

%% ~Make other sections like Warning with \section{Warning }{....} ~

\seealso{
%%  ~~objects to See Also as \code{\link{~~fun~~}}, ~~~
%%  ~~or \code{\linkS4class{CLASSNAME}} for links to other classes ~~~
}
\examples{
showClass("TimeSeriesYears")
}
\keyword{classes}
