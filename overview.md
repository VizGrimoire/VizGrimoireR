# Metrics Grimoire Overview

## Bitergia

[[Bitergia |http://bitergia.com/]] is a company from Spain that is developing open source tools to mine, analyze, and visualize open source project data. They originally started from a research group at the [[University Rey Juan Carlos|http://www.urjc.es/]] in Madrid called [[LibreSoft|http://libresoft.es/]]. 

Bitergia's present business model is one of consulting and analysis, so they give away the tools for free.

## Description

The Metrics Grimoire tool set is composed of 3 tool sets, Metrics
Grimoire, VizGrimoireR and VizGrimoireJS.  Metrics Grimoire is the
most mature and stable of the tools sets.  VizGrimoireR is mostly
stable, but there are defects that affect the ability to create
results.  VizGrimoireJS is the least stable, but is usable with just a
little set up.

### Metrics Grimore
[[MetricsGrimoire |http://metricsgrimoire.github.io/]] is the core set of tools for mining project data from source code repositories, defect trackers, mailing lists, and other project resources. The name of the project is pronounced: "metrics grim - war"

MetricsGrimoire is broken up into several different components:
* **CVSAnaly** \- extract data from source code repositories, including CVS, Subversion, git, and several others
* **Bicho** \- Extract data from defect tracking systems, including GitHub, Launchpad, and several others
* **MailingListStats** \- Collect information from project mailing lists, can use raw mail mbox files, or talk to a web-based Mailman instance
* **CMetrics** \- Extracts some code metrics (size, complexity, etc) from C code

### VizGrimoireR

The second set of tools is used to parse the data in the data base and
create more data base tables and entries.  Finally the tool set
creates a set of json files for use in visualizing the results.

### VizGrimoireJS

The final tool set is used to display the results.  The tools are
exported to the web root and json data collected by VizGrimoireR is
displayed.  This tool set is the most recent.

## Documentation, where?

Each Metrics Grimoire has it's own docuementation for installation.
Use the **README** or **README.md** file on github or in your local copy of the sources.

There is not much documentation (yet) for the other tool sets.  This
document is an attempt to help remedy that.

### Metrics Grimoire

Below are the links to the README for each individual tool in Metrics Grimoire.
* [RepositoryHandler README](https://github.com/MetricsGrimoire/RepositoryHandler/blob/master/README)
* [CVSAnalY README](https://github.com/MetricsGrimoire/CVSAnalY/blob/master/README.md)
* [Bicho README](https://github.com/MetricsGrimoire/Bicho/blob/master/README)
* [MailingListStats README](https://github.com/MetricsGrimoire/MailingListStats/blob/master/README.md)
* [CMetrics README](https://github.com/MetricsGrimoire/CMetrics/blob/master/README)


[Ubuntu 12.04 Example](https://github.com/markdo/vizgrimoire.github.com/wiki/ubuntu_example "Ubuntu 12.04 Example")
