##
## TimeSeriesYears class
##
## Class for handling a time series with years as periods.
## The time series can represent one or more variables
## evolving over time, obtained from columns in a data frame

setClass(Class="TimeSeriesYears",
         contains="ts",
         representation=representation(
           labels = "vector"
           )
         )
##
## Initialization
##
## Parameters:
##  - data: data frame with a column called "year", and one or more columns
##          with annual data. Each row will correspond to the specified year.
##          The year column doesn't need to be ordered, and there may be
##          gaps in the years. Before producing the object, the data will
##          be ordered, and gaps filled with 0.
##  - columns: Vector with the list of columns of data to use for the object.
##  - labels: Vector with the labels to use for the parameter in each column.
##
setMethod(f="initialize",
          signature="TimeSeriesYears",
          definition=function(.Object,data,columns,labels=columns) {
            cat("~~~ TimeSeriesYears: initializator ~~~ \n")
            # Select the columns to consider
            selected.data <- data[,c(as.character(columns),"year")]
            ## Order the data by year, just in case
            sorted.data <- selected.data[order(selected.data$year),]
            ## Now, fill in gaps with 0, just in case
            year.min <- sorted.data$year[1]
            year.max <- sorted.data$year[length(sorted.data$year)]
            all.years <- seq (year.min, year.max)
            all.years.df <- data.frame(list(year=all.years))
            filled.data <- merge(all.years.df,sorted.data, all=TRUE)
            filled.data[is.na(filled.data)] <- 0
            # And finally, build the object
            as(.Object, "ts") <- ts (filled.data[,as.character(columns)],
                                     start=filled.data$year[1])
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
setMethod(
  f="Plot",
  signature="TimeSeriesYears",
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
## Create a JSON file out of a TimeSeriesYears object
##
## Parameters:
##  - filename: name of the JSON file to write
##
setMethod(
  f="JSON",
  signature="TimeSeriesYears",
  definition=function(.Object, filename) {
    years <- seq (start(.Object)[1], end(.Object)[1])
    df <- data.frame(years=years, data.frame (as.ts(.Object)))
    data <- list (data = df, labels = .Object@labels)
    sink(filename)
    cat(toJSON(data))
    sink()
  }
  )
