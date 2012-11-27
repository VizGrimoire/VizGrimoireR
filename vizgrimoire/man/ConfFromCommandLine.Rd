\name{ConfFromCommandLine}
\alias{ConfFromCommandLine}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{
  %%  ~~function to do ... ~~
  Configuration from command line arguments
}
\description{
%%  ~~ A concise (1-5 lines) description of what the function does. ~~
}
\usage{
ConfFromCommandLine()
}
%- maybe also 'usage' for other objects documented here.
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
function () 
{
    args <- commandArgs(trailingOnly = TRUE)
    if (length(args) > 3) {
        enddate <- args[4]
    }
    else {
        enddate <- "2100-01-01"
    }
    enddatesplit <- strsplit(enddate, "-")
    endyear <- enddatesplit[[1]][1]
    endmonth <- enddatesplit[[1]][2]
    enddate <- paste(c("'", enddate, "'"), collapse = "")
    if (length(args) > 4) {
        startdate <- args[5]
    }
    else {
        startdate <- "1900-01-01"
    }
    startdatesplit <- strsplit(startdate, "-")
    startyear <- startdatesplit[[1]][1]
    startmonth <- startdatesplit[[1]][2]
    startdate <- paste(c("'", startdate, "'"), collapse = "")
    conf <- list(database = args[1], user = args[2], password = args[3], 
        startdate = startdate, enddate = enddate)
    return(conf)
  }
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{ ~kwd1 }
\keyword{ ~kwd2 }% __ONLY ONE__ keyword per line
