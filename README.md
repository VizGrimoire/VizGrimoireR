vizGrimoireR
============

Some R code to make life easier to those using Metrics Grimoire tools, and maybe vizGrimoireJS.

Each class is defined in the corresponding file, with a name starting with "Class", followed by the name of the class. For example, class Query is defined in file ClassQuery.

Query class hierarchy
---------------------

Hierarchy of R classes to deal with queries on SQL databases created by Metrics Grimoire.

### Query: Root of the hierarchy

Methods:

* run: Returns a data frame with selected rows and field

Times class hierarchy
---------------------

Hierarchy for handling a vector with times for certain events (for example, time to fix for a list of tickets)

### Times: Root of the hierarchy, inherits from vector

Methods:

* initalize (constructor): accepts vector with times, and strings with units and label

* PlotDist: Plots distribution of times (several histograms and density of probability)

Example of use:

    tofix <- new ("Times", issues_closed$ttofix, "days",
                  "Time to fix, first close")
    PlotDist (tofix, 'its-distrib_time_to_fix')
