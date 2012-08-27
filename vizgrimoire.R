# Copyright (C) 2012 Bitergia
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
# vizgrimoire.R
#
# R library for the vizgrimoire system
#
# Authors:
#       Jesus M. Gonzalez-Barahona <jgb@bitergia.com>
#	Daniel Izquierdo Cortazar <dizquierdo@bitergia.com>
#

# To install RColorBrewer
# $sudo R
# > install.packages('RColorBrewer', dep = T)
# Note use display.brewer.pal(...) to check colors
# example: display.brewer.pal(9, "Greens")
library(RColorBrewer)

blues = brewer.pal(5,'Blues')
reds = brewer.pal(5,'Reds')
greens = brewer.pal(5,'Greens')

#
# List of colors for plots
#
colors <- c("black", "green", "red", "blue", "orange", "brown")


# Complete a weekly dataframe with zero for missing weeks
#
# Gets as input a dataframe with weekly data. It hast to
# include a "yearweek" column, which is an integer year*52+week
# Produces a dataframe with zero rows for missing weeks
#
completeZeroWeekly <- function (data) {

  firstweek = as.integer(data$yearweek[1])
  lastweek = as.integer(data$yearweek[nrow(data)])
  weeks = data.frame('yearweek'=c(firstweek:lastweek))
  completedata <- merge (data, weeks, all=TRUE)
  completedata[is.na(completedata)] <- 0
  return (completedata)
}

# Merge two dataframes with weekly data, filling holes with 0
#
# Both dataframes should have a "yearweek" column,
# which is an integer year*52+week
#
mergeWeekly <- function (d1, d2) {

  d = completeZeroWeekly (merge (d1, d2, all=TRUE))

  return (d)
}

# Complete a monthly dataframe with zero for missing months
#
# Gets as input a dataframe with montly data. It hast to
# include a "id" column, which is an integer year*12+month
# Produces a dataframe with zero rows for missing months
#
completeZeroMonthly <- function (data) {

  firstmonth = as.integer(data$id[1])
  lastmonth = as.integer(data$id[nrow(data)])
  months = data.frame('id'=c(firstmonth:lastmonth))
  completedata <- merge (data, months, all=TRUE)
  completedata[is.na(completedata)] <- 0
  return (completedata)
}

# Merge two dataframes with monthly data, filling holes with 0
#
# Both dataframes should have a "id" column,
# which is an integer year*12+week
#
mergeMonthly <- function (d1, d2) {

  d = completeZeroMonthly (merge (d1, d2, all=TRUE))

  return (d)
}

#
# Obtain a data frame with yearly quantiles data 
#
# The produced data frame will have one column per quantile,
# plus one 'year' column, and one row per year
# The parameter 'data' will be a data frame with information about issues
# (tickets), with a column 'year_open' which will be used as
# the year of the issue.
#
toQuantilesYear <- function (data, qspec, firstYear = data$year_open[1],
                             lastYear = data$year_open[nrow(data)]) {

  # Prepare the quantiles matrix, with data for the quantiles of
  # each year in rows, and data for each quantile in columns
  # It will be a matrix of quantiles columns, and years rows
  # Column names will be quantiles (as strings), row names will be
  # years (as strings)
  years <- firstYear:lastYear
  quantiles <- matrix(nrow=length(years),ncol=length(qspec))
  colnames (quantiles) <- qspec
  rownames (quantiles) <- years
  # Now, fill in the quantiles matrix with data
  for (year in firstYear:lastYear) {
    yearData <- data[data$year_open == year,]
    time_to_fix_minutes <- yearData$ttofixm
    quantiles[as.character(year),] <- quantile(time_to_fix_minutes,
                                               qspec, names = FALSE)
  }
  #quantiles <- log10 (quantiles)
  # Now, build a data frame out of the matrix, and return it
  quantilesdf <- as.data.frame(quantiles,row.names=FALSE)
  quantilesdf$year <- years
  return (quantilesdf)
}

#
# Plot several columns of a timeserie
#
#  data: data frame to plot
#  columns: names of the columns in data frame to plot
#  labels: strings to show as labels
#

plotTimeSerieWeekN <- function (data, columns, filename, labels=columns) {

  pdffilename <- paste (c(filename, ".pdf"), collapse='')
  pdffilenamediff <- paste (c(filename, "-diff.pdf"), collapse='')
  pdffilenamecum <- paste (c(filename, "-cumsum.pdf"), collapse='')
  
  # Build label for Y axis
  label <- ""
  for (col in 1:length(columns)) {
    if (col != 1) {
      label <- paste (c(label, " / "), collapse='')
    }
    label = paste (c(label, labels[col], " (", colors[col] ,")"),
      collapse='')
  }
  
  # Regular plot
  pdf(file=pdffilename, height=3.5, width=5)
  timeserie <- ts (data[columns[1]],
                   start=c(data$year[1],data$week[1]), frequency=52)
  ts.plot (timeserie, col=colors[1], ylab=label)
  if (length (columns) > 1) {
    for (col in 2:length(columns)) {
      timeserie <- ts (data[columns[col]],
                       start=c(data$year[1],data$week[1]), frequency=52)
      lines (timeserie, col=colors[col])
    }
  }
  dev.off()

# Cummulative plot
#    pdf(file=pdffilenamecum, height=3.5, width=5)
#    timeserie <- ts (cumsum(data[columns[1]]),
#       start=c(data$year[1],data$month[1]), frequency=12)
#    ts.plot (timeserie, col=colors[1], ylab=label)
#    if (length (columns) > 1) {
#       for (col in 2:length(columns)) {
#          timeserie <- ts (cumsum(data[columns[col]]),
#             start=c(data$year[1],data$month[1]), frequency=12)
#          lines (timeserie, col=colors[col])
#       }
#    }
#    dev.off()
}

#
# Plot several columns of a timeserie
#
#  data: data frame to plot
#  columns: names of the columns in data frame to plot
#  labels: strings to show as labels
#

plotTimeSerieMonthN <- function (data, columns, filename, labels=columns) {

  pdffilename <- paste (c(filename, ".pdf"), collapse='')
  pdffilenamediff <- paste (c(filename, "-diff.pdf"), collapse='')
  pdffilenamecum <- paste (c(filename, "-cumsum.pdf"), collapse='')
  
  # Build label for Y axis
  label <- ""
  for (col in 1:length(columns)) {
    if (col != 1) {
      label <- paste (c(label, " / "), collapse='')
    }
    label = paste (c(label, labels[col], " (", colors[col] ,")"),
      collapse='')
  }
  
  # Regular plot
  pdf(file=pdffilename, height=3.5, width=5)
  timeserie <- ts (data[columns[1]],
                   start=c(data$year[1],data$month[1]), frequency=12)
  ts.plot (timeserie, col=colors[1], ylab=label)
  if (length (columns) > 1) {
    for (col in 2:length(columns)) {
      timeserie <- ts (data[columns[col]],
                       start=c(data$year[1],data$month[1]), frequency=12)
      lines (timeserie, col=colors[col])
    }
  }
  dev.off()

# Cummulative plot
#    pdf(file=pdffilenamecum, height=3.5, width=5)
#    timeserie <- ts (cumsum(data[columns[1]]),
#       start=c(data$year[1],data$month[1]), frequency=12)
#    ts.plot (timeserie, col=colors[1], ylab=label)
#    if (length (columns) > 1) {
#       for (col in 2:length(columns)) {
#          timeserie <- ts (cumsum(data[columns[col]]),
#             start=c(data$year[1],data$month[1]), frequency=12)
#          lines (timeserie, col=colors[col])
#       }
#    }
#    dev.off()
}

plotTimeSerieYearN <- function (data, columns, filename, labels=columns) {

  pdffilename <- paste (c(filename, ".pdf"), collapse='')
  pdffilenamelog <- paste (c(filename, "-log.pdf"), collapse='')
  pdffilenamediff <- paste (c(filename, "-diff.pdf"), collapse='')
  pdffilenamecum <- paste (c(filename, "-cumsum.pdf"), collapse='')

  # Build label for Y axis
  label <- ""
  for (col in 1:length(columns)) {
    if (col != 1) {
      label <- paste (c(label, " / "), collapse='')
    }
    label = paste (c(label, labels[col], " (", colors[col] ,")"),
      collapse='')
  }
  
  timeserie <- ts (data[columns], start=data$year[1])
  ## Regular plot
  pdf(file=pdffilename, height=3.5, width=5)
  ts.plot (timeserie, gpars=list(col=colors, ylab=label))
  dev.off()
  ## Log10 plot
  pdf(file=pdffilenamelog, height=3.5, width=5)
  ts.plot (log10(timeserie), gpars=list(col=colors, ylab=label))
  dev.off()
  
  
# Cummulative plot
#    pdf(file=pdffilenamecum, height=3.5, width=5)
#    timeserie <- ts (cumsum(data[columns[1]]),
#       start=c(data$year[1],data$month[1]), frequency=12)
#    ts.plot (timeserie, col=colors[1], ylab=label)
#    if (length (columns) > 1) {
#       for (col in 2:length(columns)) {
#          timeserie <- ts (cumsum(data[columns[col]]),
#             start=c(data$year[1],data$month[1]), frequency=12)
#          lines (timeserie, col=colors[col])
#       }
#    }
#    dev.off()
}


#
# Plot histogram and density of probability for data frame (single column)
#
plotHistogramTime <- function (data, filename, label, title='') {

  pdffilename <- paste (c(filename, ".pdf"), collapse='')
  pdf(pdffilename, height=5, width=5)
  hist(data, prob= T, breaks='FD', col=blues[3], xlab = label, main = title)
  lines(density(data), col=reds[3], lwd = 2)
  dev.off()
}
#library(vioplot)

#
# Plot boxplot for data frame
#
plotBoxPlot <- function (data, filename, label = '', title = '') {
  
  pdffilename <- paste (c(filename, ".pdf"), collapse='')
  pdf(pdffilename, height=10, width=2)
  boxplot(data, col = greens[2], main = title, ylab = "days", xlab = label)
  # Mark top 3 outliers
  #top3 = rev(sort(data))[1:3]
  #print(top3)
  #text(rep(1,3), y = top3, label = paste(top3, 'days'), pos = 4)
  dev.off()
}

#
# Plot distribution of times
#
# Plots several charts:
#  - Histogram and density of probability for all tickets
#  - Histogram and density of probability for quickly closed tickets
#  - Histogram and density of probability for slowly closed tickets
# Threshold is for splitting in quick/slow (in days)
#
plotTimeDist <- function (data, filename, unit = 'days', threshold = 30,
                          variable = 'Time') {

  label <- paste (c(variable, ' (', unit, ')'), collapse='')
  # All tickets
  plotHistogramTime (data, filename, label)
  plotBoxPlot (data, paste (c (filename, '-boxplot'), collapse=''))
  # Quickly closed tickets
  quickly <- data[data <= threshold]
  if (length(quickly) > 0) {
    plotHistogramTime (quickly, paste (c (filename, '-quick'), collapse=''),
                       label)
    plotBoxPlot (quickly, paste (c (filename, '-quick-boxplot'), collapse=''))
  }
  # Slowly closed tickets
  slowly <- data[data > threshold]
  if (length(slowly) > 0) {
    plotHistogramTime (slowly, paste (c (filename, '-slow'), collapse=''),
                       label)
    plotBoxPlot (slowly, paste (c (filename, '-slow-boxplot'), collapse=''))
  }
#  pdf(paste (c (filename, '-vioplot.pdf'), collapse=''), height=10, width=4)
#  vioplot(data, quickly, slowly, col='gold', varwidth=TRUE)
#  dev.off()
}

#
# Plot time distributions and boxplots for time to fix in all years
#
plotTimeDistYear <- function (data, filename) {
  for (year in data$year_open[1] : data$year_open[nrow(data)]) {
    filename = paste(c(filename, '-',year), collapse='')
    yearData <- data[data$year_open == year,]
    plotTimeDist (yearData$ttofixm, filename, 'minutes',
                  variable = 'Time to fix, first close')
  }
}

library(rjson)
#
# Create a JSON file with some R object
#
createJSON <- function (data, filename) {
  sink(filename)
  cat(toJSON(data))
  sink()
}

#
# Database-related functions
#

  
query <- function(...) dbGetQuery(mychannel, ...)
