vizGrimoireR
============

R package vizgrimoire, to make life easier to those using Metrics Grimoire tools, and maybe vizGrimoireJS.

Installation from source
------------------------

From the parent directory of vizgrimoire:

% R CMD INSTALL vizgrimoire

Or locally:

% R CMD INSTALL -l <local_dir> vizgrimoire
% R_LIBS=<local_dir>:$R_LIBS R --vanilla ....

Or, to produce a tarball, from the vizgrimoire directory:

% R CMD build # To build the package tarball
% R CMD check # To check the package tarball

General issues
--------------

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

* JSON: Dumps a JSON file

* QuantilizeYears: Obtains a data frame with yearly quantiles data. Each column in the data frame will correspond to the quantiles for each year.

#### Example:

    issues_closed <- new ("ITSTicketsTimes")
    quantiles_ttofixm_year <- QuantilizeYears (issues_closed, quantiles_spec)
    plotTimeSerieYearN (quantiles_ttofixm_year, as.character(quantiles_spec),
                    'its-quantiles-year-time_to_fix_min')


### ITSMonthly: class for dealing with monthly parameters

This class provides a framework for quering a database looking for aggregated monthly parameters (such as tickets open and ticker openers per month). Most of the functionality is here (initialize the object, create JSON files, etc.), but each child specializes its particularities, which are mainly the query needed to extract the data from the database.

#### Methods

* initalize (constructor): uses the query in the children to get a monthly data frame. Each row corresponds to the data for a month. Each column is either one of the parameters queried, or some auxiliary value: id (year*12+month), year, month and a char format to show the month (such as Jun 2001).

* Query: just a void class, a placeholder for children specifying the query to be performed for the specific data they contain

* JSON: writes the object into a JSON file

### ITSMonthlyOpen: class for tickets open, openers per month

Inherits from ITSMonthly.

Object with information about tickets open, and ticket openers, per month.

#### Methods

* Query: returns the SQL query to obtain the data for the object

#### Example of use

    open.monthly <- new ("ITSMonthlyOpen")
    JSON(open.monthly, "its-open-monthly.json")

### ITSMonthlyChanged: class for tickets changed, changers per month

Inherits from ITSMonthly.

Object with information about tickets changed, and ticket changers, per month.

#### Methods

* Query: returns the SQL query to obtain the data for the object

### ITSMonthlyClosed: class for tickets closed (first close) per month

Inherits from ITSMonthly.

Object with information about tickets closed (first close) per month.

#### Methods

* Query: returns the SQL query to obtain the data for the object

### ITSMonthlyLastClosed: class for tickets closed (last close) per month

Inherits from ITSMonthly.

Object with information about tickets closed (last close) per month.

#### Methods

* Query: returns the SQL query to obtain the data for the object


### ITSMonthlyVarious: class for all monthly parameters related to tickets

Inherits from ITSMonthly.

Object with information about all monthly parameters related to tickets. Internally, it instantiated objects of all the sister classes, and merges them. Therefore, no query is done directly by this class: sister classes are the ones actually querying the database.

#### Methods

* initalize (constructor): Instatiates objects of the sister classes, and merges them to obtain a data frame with all monthly parameters relevant to tickets.



Time series class hierarchy
---------------------------

Hierarchy for dealing with specialized time series

### TimeSeries: Root of the hierarchy

Still to be written

### TimeSeriesYears: Class for annual time series

Inherits from ts (should inherit from TimeSeries)

#### Methods

* initalize (constructor): Accepts time serie to initialize, along with the list of columns and the labels to use for those columns.

* Plot: Plots columns in object, using labels (if specified)

* JSON: Dumps objet to file, as JSON

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
