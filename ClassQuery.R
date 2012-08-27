#
# Query class
#
# Class for SQL queries
#
setClass(Class="Query",
         representation=representation(
           sql="character")
         )

# New method run, for class Query
# Returns a data frame with selected rows (as rows in the data frame)
#  and fields (as named columns in the data frame)
setGeneric (
  name= "run",
  def=function(object){standardGeneric("run")}
  )
setMethod(
  "run", "Query",
  function(object) {
    return (dbGetQuery(mychannel, object@sql))
  }
  )

# Override show method
setMethod(
  "show", "Query",
  function(object) {
    return (object@sql)
  }
  )
