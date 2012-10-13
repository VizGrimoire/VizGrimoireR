##
## TimeSeriesMonths class
##
## Class for handling a time series with months as periods.
## The time series can represent one or more variables
## evolving over time, obtained from columns in a data frame

setClass(Class="TimeSeriesMonths",
         contains="ts",
         representation=representation(
           labels = "vector"
           )
         )
##
## Initialization
##
## Parameters:
##  - data: data frame with a column called "period", and one or more columns
##          with annual data. Each row will correspond to the specified period,
##          in the format year*12+month (month being as 0:11).
##          The period column doesn't need to be ordered, and there may be
##          gaps in the periods. Before producing the object, the data will
##          be ordered, and gaps filled with 0.
##  - columns: Vector with the list of columns of data to use for the object.
##  - labels: Vector with the labels to use for the parameter in each column.
##
setMethod(f="initialize",
          signature="TimeSeriesMonths",
          definition=function(.Object,data,columns,labels=columns) {
            cat("~~~ TimeSeriesMonths: initializator ~~~ \n")
            ## Select the columns to consider
            selected.data <- data[,c(as.character(columns),"period")]
            ## Order the data by year, just in case
            sorted.data <- selected.data[order(selected.data$period),]
            ## Now, fill in gaps with 0, just in case
            period.min <- sorted.data$period[1]
            period.max <- sorted.data$period[length(sorted.data$period)]
            periods <- seq (period.min, period.max)
            periods.df <- data.frame(list(period=periods))
            filled.data <- merge(periods.df,sorted.data, all=TRUE)
            filled.data[is.na(filled.data)] <- 0
            ## And finally, build the object
            as(.Object, "ts") <- ts (filled.data[,as.character(columns)],
                                     start = c(filled.data$period[1] %/% 12,
                                       filled.data$period[1] %% 12 + 1),
                                     frequency = 12)
            .Object@labels <- labels
            return(.Object)
          }
          )

##
## Plot TimeSeriesYears object (or a part of it)
##
## Plots several charts:
##  - Values of selected columns over time
##  - Log values of selected columns over time
##
#setGeneric (
#  name= "Plot",
#  def=function(.Object,...){standardGeneric("Plot")}
#  )
setMethod(
  f="Plot",
  signature="TimeSeriesMonths",
  definition=function(.Object, filename, columns=colnames(.Object),
    labels=.Object@labels) {
    pdffilename <- paste (c(filename, ".pdf"), collapse='')
    pdffilenamelog <- paste (c(filename, "-log.pdf"), collapse='')
    pdffilenamediff <- paste (c(filename, "-diff.pdf"), collapse='')
    pdffilenamecum <- paste (c(filename, "-cumsum.pdf"), collapse='')
    
    ## Build label for Y axis
    label <- ""
    for (col in 1:length(columns)) {
      if (col != 1) {
        label <- paste (c(label, " / "), collapse='')
      }
      label = paste (c(label, labels[col], " (", colors[col] ,")"),
        collapse='')
    }
    
    ## Regular plot
    pdf(file=pdffilename, height=3.5, width=5)
    ts.plot (.Object, gpars=list(col=colors, ylab=label), yaxt="n")
    grid()
    dev.off()
    ## Log10 plot
    pdf(file=pdffilenamelog, height=4, width=5)
    ts.plot (log10(.Object), gpars=list(col=colors, ylab=label))
    dev.off()
  }
  )

##
## Create a JSON file out of a TimeSeriesMonths object
##
## Parameters:
##  - filename: name of the JSON file to write
##
#library(rjson)
#setGeneric (
#  name= "JSON",
#  def=function(.Object,...){standardGeneric("JSON")}
#  )
setMethod(
  f="JSON",
  signature="TimeSeriesMonths",
  definition=function(.Object, filename) {
    ## periods <- seq (start(.Object)[1], end(.Object)[1])
    periods <- seq (start(as.ts(.Object))[1]*12 + start(as.ts(.Object))[2],
                    end(as.ts(.Object))[1]*12 + end(as.ts(.Object))[2])
    df <- data.frame(period=periods, data.frame (as.ts(.Object)))
    data <- list (data = df, labels = .Object@labels)
    sink(filename)
    cat(toJSON(data))
    sink()
  }
  )
