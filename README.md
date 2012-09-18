vizGrimoireR
============

Some R code to make life easier to those using Metrics Grimoire tools, and maybe vizGrimoireJS.

Each class is defined in the corresponding file, with a name starting with "Class", followed by the name of the class. For example, class Query is defined in file ClassQuery.

Query class hierarchy
---------------------

Hierarchy of R classes to deal with queries on SQL databases created by Metrics Grimoire.

### Query: Root of the hierarchy

#### Methods:

* run: Returns a data frame with selected rows and field


### ITSTicketsTimes: class for handling the many times of each ticket

This class, when initialized, makes a query on an ITS (issue tracking system) database, and stores the result as a data frame with the many times relevant for each ticket (open, closed, changed, etc.)

#### Methods:

* initalize (constructor): Accepts a query (by default uses its own one, which should work). Stores as columns in the dataset several times: time to fix (first fix), time to fix (last fix), time to fix (in hours), etc.

* QuantilizeYears: Obtains a data frame with yearly quantiles data. Each column in the data frame will correspond to the quantiles for each year.

#### Example:

    issues_closed <- new ("ITSTicketsTimes")
    quantiles_ttofixm_year <- QuantilizeYears (issues_closed, quantiles_spec)
    plotTimeSerieYearN (quantiles_ttofixm_year, as.character(quantiles_spec),
                    'its-quantiles-year-time_to_fix_min')


Time series class hierarchy
---------------------------

Hierarchy for dealing with specialized time series

### TimeSeries: Root of the hierarchy

Still to be written

### TimeSeriesYears: Class for annual time series

Inherits from ts (should inherit from TimeSeries)

#### Methods

* initalize (constructor): accepts time serie to initialize, along with the list of columns and the labels to use for those columns.

Times class hierarchy
---------------------

Hierarchy for handling a vector with times for certain events (for example, time to fix for a list of tickets)

### Times: Root of the hierarchy

Inherits from vector

#### Methods:

* initalize (constructor): accepts vector with times, and strings with units and label

* PlotDist: Plots distribution of times (several histograms and density of probability)

#### Example of use:

    issues_closed <- new ("ITSTicketsTimes")
    tofix <- new ("Times", issues_closed$ttofix, "days",
                  "Time to fix, first close")
    PlotDist (tofix, 'its-distrib_time_to_fix')
