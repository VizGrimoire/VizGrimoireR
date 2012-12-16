\name{Query-class}
\Rdversion{1.1}
\docType{class}
\alias{Query-class}
\alias{run,Query-method}
\alias{show,Query-method}

\title{Class \code{"Query"}}
\description{
  %%  ~~ A concise (1-5 lines) description of what the class is. ~~
  Class for specifying SQL queries to databases. When instantiating
  objects, the actual query is defined. The class provides methods
  for running the class (returning a data frame with the results
  obtained from the database) and for showing the query.
}
\section{Objects from the Class}{
  Objects can be created by calls of the form \code{new("Query", sql)}.
  %%  ~~ describe objects here ~~

  Each object corresponds to an SQL query, which is defined when
  creating (instantiating) it.
}
\section{Slots}{
  \describe{
    \item{\code{sql}:}{Object of class \code{"character"}. Provides
  the SQL query that will be used by this \code{Query} object.}
  }
}
\section{Methods}{
  \describe{
    \item{run}{\code{signature(object = "Query")}: Runs the SQL query,
  returning a data frame with the results. Names of the data frame will
  correspond to the names of the fields returned by the query.}
    \item{show}{\code{signature(object = "Query")}: Returns the SQL
  query defined for the object.}
	 }
}
% \references{
% %%  ~~put references to the literature/web site here~~
% }
\author{
  %%  ~~who you are~~
  Jesus M. Gonzalez-Barahona
}
% \note{
% %%  ~~further notes~~
% }

%% ~Make other sections like Warning with \section{Warning }{....} ~

% \seealso{
% %%  ~~objects to See Also as \code{\link{~~fun~~}}, ~~~
% %%  ~~or \code{\linkS4class{CLASSNAME}} for links to other classes ~~~
% }
\examples{
showClass("Query")

q <- new ("Query", sql = "SELECT * FROM table")
}
\keyword{classes}
