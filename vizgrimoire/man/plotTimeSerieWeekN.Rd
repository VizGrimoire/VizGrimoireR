\name{plotTimeSerieWeekN}
\alias{plotTimeSerieWeekN}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{
  %%  ~~function to do ... ~~
  Plot weekly time serie.
}
\description{
%%  ~~ A concise (1-5 lines) description of what the function does. ~~
}
\usage{
plotTimeSerieWeekN(data, columns, filename, labels = columns)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{data}{
%%     ~~Describe \code{data} here~~
}
  \item{columns}{
%%     ~~Describe \code{columns} here~~
}
  \item{filename}{
%%     ~~Describe \code{filename} here~~
}
  \item{labels}{
%%     ~~Describe \code{labels} here~~
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
function (data, columns, filename, labels = columns) 
{
    pdffilename <- paste(c(filename, ".pdf"), collapse = "")
    pdffilenamediff <- paste(c(filename, "-diff.pdf"), collapse = "")
    pdffilenamecum <- paste(c(filename, "-cumsum.pdf"), collapse = "")
    label <- ""
    for (col in 1:length(columns)) {
        if (col != 1) {
            label <- paste(c(label, " / "), collapse = "")
        }
        label = paste(c(label, labels[col], " (", colors[col], 
            ")"), collapse = "")
    }
    pdf(file = pdffilename, height = 3.5, width = 5)
    timeserie <- ts(data[columns[1]], start = c(data$year[1], 
        data$week[1]), frequency = 52)
    ts.plot(timeserie, col = colors[1], ylab = label)
    if (length(columns) > 1) {
        for (col in 2:length(columns)) {
            timeserie <- ts(data[columns[col]], start = c(data$year[1], 
                data$week[1]), frequency = 52)
            lines(timeserie, col = colors[col])
        }
    }
    dev.off()
  }
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{ ~kwd1 }
\keyword{ ~kwd2 }% __ONLY ONE__ keyword per line
