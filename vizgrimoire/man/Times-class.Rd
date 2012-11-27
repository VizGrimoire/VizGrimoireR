\name{Times-class}
\Rdversion{1.1}
\docType{class}
\alias{Times-class}
\alias{initialize,Times-method}
\alias{PlotDist,Times-method}

\title{Class \code{"Times"}}
\description{
%%  ~~ A concise (1-5 lines) description of what the class is. ~~
}
\section{Objects from the Class}{
Objects can be created by calls of the form \code{new("Times", times, label)}.
%%  ~~ describe objects here ~~ 
}
\section{Slots}{
  \describe{
    \item{\code{.Data}:}{Object of class \code{"vector"} ~~ }
    \item{\code{label}:}{Object of class \code{"character"} ~~ }
  }
}
\section{Extends}{
Class \code{"\linkS4class{vector}"}, from data part.
}
\section{Methods}{
  \describe{
    \item{initialize}{\code{signature(.Object = "Times")}: ... }
    \item{PlotDist}{\code{signature(object = "Times")}: ... }
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
showClass("Times")
}
\keyword{classes}
