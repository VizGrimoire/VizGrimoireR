vizGrimoireR
============

Some R code to make life easier to those using Metrics Grimoire tools, and maybe vizGrimoireJS.

Each class is defined in the corresponding file, with a name starting with "Class", followed by the name of the class. For example, class Query is defined in file ClassQuery.

Query class hierarchy
--------------------------

Hierarchy of R classes to deal with queries on SQL databases created by Metrics Grimoire.

### Query: Root of the hierarchy

Methods:

* run: Returns a data frame with selected rows and field