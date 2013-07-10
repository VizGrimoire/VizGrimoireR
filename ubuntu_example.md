# Ubuntu 12.04 LTS example

The following examples were created using Ubuntu 12.04 LTS.  The
source code will get checked out into \<home\>/git/. To recreate the
example, substitute \<home\>/git/ for where your local git is set up.

Addtionally, we are going to use MySQL as the data base and git as the
repository to analyze.  If svn or cvs repositories need to be
analyzed, then svn and cvs should be installed on the system.

The use of sudo is also part of the examaples, if sudo or root access is not available, the tools can be installed into a directory you do have write access to.  For example, a directory in your home directory.  See the documentation for the given module.

## get the code for Metrics Grimoire
    cd <home>git
    git clone https://github.com/MetricsGrimoire/CVSAnalY.git
    git clone https://github.com/MetricsGrimoire/Bicho.git
    git clone https://github.com/MetricsGrimoire/RepositoryHandler.git
    git clone https://github.com/MetricsGrimoire/MailingListStats.git
    git clone https://github.com/MetricsGrimoire/CMetrics.git

## Prepare the system

* install python and needed modules:
  * Python 2.7>
  * python-setuptools 
  * python-pysqlite2
  * python-storm
  * python-launchpadlib
  * python-beautifulsoup
  * python-feedparser
  * python-configglue
  * python-mysqldb

These all can be install by: sudo apt-get install \<list-of-python-modules\>.

## Installing MetricsGrimoire

After getting the sources with the steps above, the tools still need to be installed on the system. RepositoryHandler should be installed first since CVSAnalY depends on it and will try to install it if it is not there, most likely failing. 

    cd \<home\>/Git/RepositoryHandler
    python setup.py build
    sudo python setup.py install
    cd ../CVAnalY
    python setup.py build
    sudo python setup.py install
    ....  (the steps are basically the same for the other modules, see the README for each module)  

On Ubuntu 12.04, these were installed in **/usr/local/bin**.  **Note** CVSAnalY installs as **cvsanaly2**.
The supporting python infrastructure was installed in **/usr/local/lib/python2.7/dist-packages/**.

# VizgrimoireR and  VizgrimoireJS

Use git to obtain a clone of the repositories.

    cd \<home\>/Git
    git clone https://github.com/VizGrimoire/VizGrimoireR.git
    git clone https://github.com/VizGrimoire/VizGrimoireJS.git

## VizgrimoireR
VizgrimoireR requires that *R* is installed on the system as it uses that to install itself.

For ubuntu 12.04 the following worked.
* Make sure r-base-core and r-base-dev are installed on the system, you can use apt for this.
* install the other needed cran modules:
  * r-cran-boot
  * r-cran-class
  * r-cran-cluster
  * r-cran-codetools
  * r-cran-dbi
  * r-cran-foreign
  * r-cran-kernsmooth
  * r-cran-lattice
  * r-cran-mass
  * r-cran-matrix
  * r-cran-mgcv
  * r-cran-nlme
  * r-cran-nnet
  * r-cran-rgl
  * r-cran-rmysql
  * r-cran-rpart
  * r-cran-spatial
  * r-cran-survival

This should work:

     sudo apt-get install r-cran-boot r-cran-class r-cran-cluster r-cran-codetools r-cran-dbi 
     r-cran-foreign r-cran-kernsmooth r-cran-lattice r-cran-mass r-cran-matrix r-cran-mgcv 
     r-cran-nlme r-cran-nnet r-cran-rgl r-cran-rmysql r-cran-rpart r-cran-spatial r-cran-survival 

* VizgrimoireR also needs some other libraries, the easiest way to install them is to use **R** itself.
* run the **R** shell. At the shell prompt, type **sudo R**, run it as sudo to install in the system directories.  If you can't run sudo, **R** will install into a local directory in your home.  Answer the **R** prompts in this case.  The **R** prompt is \>.
* at the **R** prompt:

        p\<-c("ggplot2", "rjson", "optparse", "zoo")
        install.packages(p)
        # quit R 
        q()
 
* Next install vizgrimoire:
 
        cd \<home\>/Git/VizGrimoireR
        sudo R CMD INSTALL vizgrimoire

When vizgrimoire was installed on a laptop, there were no warnings.  When installed on a VM with no display the following warnings occured.

    * installing to library ‘/home/markd/R/x86_64-pc-linux-gnu-library/2.14’
    * installing *source* package ‘vizgrimoire’ ...
    ** R
    ** preparing package for lazy loading
    Warning in rgl.init(initValue) : RGL: unable to open X11 display
    Warning in fun(libname, pkgname) : error in rgl_init
    ~~~ Ages: initializator ~~~ 
    ~~~ Ages: initializator ~~~ 
    ** help
    *** installing help indices
    ** building package indices ...
    ** testing if installed package can be loaded
    Warning messages:
    1: In rgl.init(initValue) : RGL: unable to open X11 display
    2: In fun(libname, pkgname) : error in rgl_init

    * DONE (vizgrimoire)

The warnings did not prevent visgrimoire from installing and later it appears to work just fine.

Wow! That was a lot of work.  Now we are ready to gather some metrics.  Next [scm metrics](scm-metrics) will be gathered. 

