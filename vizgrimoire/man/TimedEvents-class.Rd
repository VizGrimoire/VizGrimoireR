\name{TimedEvents-class}
\Rdversion{1.1}
\docType{class}
\alias{TimedEvents-class}
\alias{initialize,TimedEvents-method}
\alias{QuantilizeMonths,TimedEvents-method}
\alias{QuantilizeYears,TimedEvents-method}

\title{Class \code{"TimedEvents"}}
\description{
%%  ~~ A concise (1-5 lines) description of what the class is. ~~
}
\section{Objects from the Class}{
Objects can be created by calls of the form \code{new("TimedEvents", timestamps, parameters)}.
%%  ~~ describe objects here ~~ 
}
\section{Slots}{
  \describe{
    \item{\code{.Data}:}{Object of class \code{"list"} ~~ }
    \item{\code{names}:}{Object of class \code{"character"} ~~ }
    \item{\code{row.names}:}{Object of class \code{"data.frameRowLabels"} ~~ }
    \item{\code{.S3Class}:}{Object of class \code{"character"} ~~ }
  }
}
\section{Extends}{
Class \code{"\linkS4class{data.frame}"}, directly.
Class \code{"\linkS4class{list}"}, by class "data.frame", distance 2.
Class \code{"\linkS4class{oldClass}"}, by class "data.frame", distance 2.
Class \code{"\linkS4class{vector}"}, by class "data.frame", distance 3.
}
\section{Methods}{
  \describe{
    \item{initialize}{\code{signature(.Object = "TimedEvents")}: ... }
    \item{QuantilizeMonths}{\code{signature(object = "TimedEvents")}: ... }
    \item{QuantilizeYears}{\code{signature(object = "TimedEvents")}: ... }
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
showClass("TimedEvents")
}
\keyword{classes}
