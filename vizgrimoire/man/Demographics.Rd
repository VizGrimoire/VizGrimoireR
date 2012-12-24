\name{Demographics}
\alias{Demobraphics}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{
  %%  ~~function to do ... ~~
  Class for handling demographics about developers
}
\description{
  %%  ~~ A concise (1-5 lines) description of what the function does. ~~
  This class encapsulates information about when develpers have
  been active in the project. That includes when they were first and
  last seen as active, their activity (in number of commits) and
  their identifiers (unique id, name, email address).
  When an object of this class is instantiated, the corresponding query
  is done on the database, so it does not need initialization data.
}
\usage{
Demographics(.Object)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{.Object}{
    Includes the results of the query to the database.
}
  \item{\dots}{
%%     ~~Describe \code{\dots} here~~
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
structure(function (.Object, ...) 
{
    standardGeneric("Query")
  }, generic = structure("Query", package = "vizgrimoire"), package = "vizgrimoire", group = list(), valueClass = character(0), signature = ".Object", default = `\001NULL\001`, skeleton = function (.Object, 
    ...) 
stop("invalid call in method dispatch to \"Query\" (no default method)", 
    domain = NA)(.Object, ...), class = structure("nonstandardGenericFunction", package = "methods"))
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{ ~kwd1 }
\keyword{ ~kwd2 }% __ONLY ONE__ keyword per line
