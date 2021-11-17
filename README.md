# synapserprototype

This package is heavily inspired by [rstudio/tensorflow](https://github.com/rstudio/tensorflow) and follows the same
format to leverage reticulate to install the Python [synapseclient](https://github.com/Sage-Bionetworks/synapsePythonClient).


## Installation Guide
This installation guide mimics that of the [rstudio/tensorflow installation guide](https://tensorflow.rstudio.com/installation/).

Prior to using the synapseprototype R package you need to install a version of synapseclient on your system. Below we describe how to install synapseclient as well the various options available for customizing your installation.

Note that this article principally covers the use of the R install_synapseclient() function, which provides an easy to use wrapper for the various steps required to install synapseclient.

### Installation
First, install the synapseprototype R package from GitHub as follows:

remotes::install_github("https://github.com/thomasyu888/synapserprototype")

Then, use the install_synapseclient() function to install synapseclient. Note that on Windows you need a working installation of Anaconda.

```
library(synapserprototype)
install_synapsecilent()
```

You can confirm that the installation succeeded with:

```
library(synapserprototype)
syn$`__version__`
```

This will provide you with a default installation of synapseclient suitable for use with the synapserprototype R package.

### Installation methods

synapseclient needs to be installed within a Python environment on your system. By default, the `install_synapseclient()` function attempts to install synapseclient within an isolated Python environment ("r-reticulate").

These are the available methods and their behavior:

| Method|Description|
| --- | ----------- |
|auto|	Automatically choose an appropriate default for the current platform.|
|virtualenv|	Install into a Python virtual environment at `~/.virtualenvs/r-reticulate`|
|conda	|Install into an Anaconda Python environment named `r-reticulate`|
|system|	Install into the system Python environment|

The "virtualenv" and "conda" methods are available on Linux and OS X and only the "conda" method is available on Windows.

`install_synapseclient` is a wraper around `reticulate::py_install`. Please refer to 'Installing Python Packages' for more information.

### Alternate Versions

By default, `install_synaspeclient()` install the latest release version of synapseclient. You can override this behavior by specifying the version parameter. For example:

`install_synapseclient(version = "2.4.0")`
