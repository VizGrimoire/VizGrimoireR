\name{vizgrimoire-package}
\alias{vizgrimoire-package}
\alias{vizgrimoire}
\docType{package}
\title{
  Making life easier to users of Metrics Grimoire tools, and vizGrimoireJS
}
\description{
  Metrics Grimoire tools extract information from software development
  repositories such as git or Bugzilla, and store it in an SQL
  database. This package assists in analyzing data from that database,
  with the aim of producing quantitative analysis of several software
  development aspects. Some of the analysis can be lated visualized with
  vizGrimoireJS (JSON files are produced with that aim).
}
\details{
\tabular{ll}{
Package: \tab vizgrimoire\cr
Type: \tab Package\cr
Version: \tab 1.0\cr
Date: \tab 2012-12-16\cr
License: \tab GPL version 3 or later\cr
Depends: \tab RMySQL, rjson, RColorBrewer\cr
}
The package provides several hierarchies of classes, each one oriented
towards a certain kind of analysis. Usually, analysis start with
retrieving some data from databases produced by Metrics Grimoire tools,
and as a result produce charts, JSON files and other output information.
}
\author{
Jesus M. Gonzalez-Barahona

%Maintainer: Who to complain to <yourfault@somewhere.net>
%~~ The author and/or maintainer of the package ~~
}
% \references{
% ~~ Literature or other references for background information ~~
% }
% ~~ Optionally other standard keywords, one per line, from file KEYWORDS in ~~
% ~~ the R documentation directory ~~
% \keyword{ package }
% \seealso{
% ~~ Optional links to other man pages, e.g. ~~
% ~~ \code{\link[<pkg>:<pkg>-package]{<pkg>}} ~~
% }
\examples{
SetDBChannel (conf$user, conf$password, conf$database)
conf$repokind <- FindoutRepoKind ()
closed <- new ("ITSTicketsTimes")
JSON(closed, 'its-issues_closed.json')
}
