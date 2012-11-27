\name{plotTimeDist}
\alias{plotTimeDist}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{
  %%  ~~function to do ... ~~
  Plot time distribution.
}
\description{
%%  ~~ A concise (1-5 lines) description of what the function does. ~~
}
\usage{
plotTimeDist(data, filename, unit = "days", threshold = 30, variable = "Time")
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{data}{
%%     ~~Describe \code{data} here~~
}
  \item{filename}{
%%     ~~Describe \code{filename} here~~
}
  \item{unit}{
%%     ~~Describe \code{unit} here~~
}
  \item{threshold}{
%%     ~~Describe \code{threshold} here~~
}
  \item{variable}{
%%     ~~Describe \code{variable} here~~
}
}
\details{
%%  ~~ If necessary, more details than the description above ~~
}
\value{
%%  ~Describe the value returned
%%  If it is a LIST, use
%%  \item{comp1 }{Description of 'comp1'}
%%  \item{comp2 }{Description of 'comp2'}
%% ...
}
\references{
%% ~put references to the literature/web site here ~
}
\author{
%%  ~~who you are~~
}
\note{
%%  ~~further notes~~
}

%% ~Make other sections like Warning with \section{Warning }{....} ~

\seealso{
%% ~~objects to See Also as \code{\link{help}}, ~~~
}
\examples{
##---- Should be DIRECTLY executable !! ----
##-- ==>  Define data, use random,
##--	or do  help(data=index)  for the standard data sets.

## The function is currently defined as
function (data, filename, unit = "days", threshold = 30, variable = "Time") 
{
    label <- paste(c(variable, " (", unit, ")"), collapse = "")
    plotHistogramTime(data, filename, label)
    plotBoxPlot(data, paste(c(filename, "-boxplot"), collapse = ""))
    quickly <- data[data <= threshold]
    if (length(quickly) > 0) {
        plotHistogramTime(quickly, paste(c(filename, "-quick"), 
            collapse = ""), label)
        plotBoxPlot(quickly, paste(c(filename, "-quick-boxplot"), 
            collapse = ""))
    }
    slowly <- data[data > threshold]
    if (length(slowly) > 0) {
        plotHistogramTime(slowly, paste(c(filename, "-slow"), 
            collapse = ""), label)
        plotBoxPlot(slowly, paste(c(filename, "-slow-boxplot"), 
            collapse = ""))
    }
  }
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{ ~kwd1 }
\keyword{ ~kwd2 }% __ONLY ONE__ keyword per line
