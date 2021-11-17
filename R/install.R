#'  inspiration from rstudio/tensorflow
#'  Install synapseclient and its dependencies
#'
#' `install_synapseclient()` installs the synapseclient python package and
#' it's direct and optional dependencies.
#'
#' @details You may be prompted you if you want it to download and install
#'   miniconda if reticulate did not find a non-system installation of python.
#'   Miniconda is the recommended installation method for most users, as it
#'   ensures that the R python installation is isolated from other python
#'   installations. All python packages will by default be installed into a
#'   self-contained conda or venv environment named "r-reticulate". Note that
#'   "conda" is the only supported method on Windows.
#'
#'   If you initially declined the miniconda installation prompt, you can later
#'   manually install miniconda by running [`reticulate::install_miniconda()`].
#'
#' @section Custom Installation: `install_synapseclient()` or
#'   isn't required to use synapseclient with the package.
#'   If you manually configure a python environment with the required
#'   dependencies, you can tell R to use it by pointing reticulate at it,
#'   commonly by setting an environment variable:
#'
#'   ``` Sys.setenv("RETICULATE_PYTHON" = "~/path/to/python-env/bin/python") ```
#'
#'
#' @section Additional Packages:
#'
#'   If you wish to add additional PyPI packages to your synapseclient
#'   environment you can either specify the packages in the `extra_packages`
#'   argument of `install_synapseclient()` or alternatively
#'   install them into an existing environment using the
#'   [reticulate::py_install()] function.
#'
#' @md
#'
#' @inheritParams reticulate::py_install
#'
#' @param version TensorFlow version to install. Valid values include:
#'
#'   +  `"default"` installs  `r default_version`
#'
#'   + `"release"` installs the latest release version of tensorflow (which may
#'   be incompatible with the current version of the R package)
#'
#'   + A version specification like `"2.4"` or `"2.4.0"`. Note that if the patch
#'   version is not supplied, the latest patch release is installed (e.g.,
#'   `"2.4"` today installs version "2.4.2")
#'
#'   + `nightly` for the latest available nightly build.
#'
#'   + To any specification, you can append "-cpu" to install the cpu version
#'   only of the package (e.g., `"2.4-cpu"`)
#'
#'   + The full URL or path to a installer binary or python *.whl file.
#'
#' @param extra_packages Additional Python packages to install along with
#'   TensorFlow.
#'
#' @param restart_session Restart R session after installing (note this will
#'   only occur within RStudio).
#'
#' @param python_version,conda_python_version the python version installed in
#'   the created conda environment. Ignored when attempting to install with a
#'   Python virtual environment.
#'
#' @param pip_ignore_installed Whether pip should ignore installed python
#'   packages and reinstall all already installed python packages. This defaults
#'   to `TRUE`, to ensure that TensorFlow dependencies like NumPy are compatible
#'   with the prebuilt TensorFlow binaries.
#'
#' @param ... other arguments passed to [`reticulate::conda_install()`] or
#'   [`reticulate::virtualenv_install()`], depending on the `method` used.
#'
#' @export
install_synapseclient <- function(method = c("auto", "virtualenv", "conda"),
                                  conda = "auto",
                                  version = "default",
                                  envname = NULL,
                                  extra_packages = NULL,
                                  restart_session = TRUE,
                                  conda_python_version = "3.7",
                                  ...,
                                  pip_ignore_installed = TRUE,
                                  python_version = conda_python_version) {

  if(is_apple_silicon()) {
    stop("Automatic installation on M1 Macs not supported yet.",
         ' Please consult `?install_synapseclient` help section on "Apple silicon"',
         " for alternatives.")
  }

  # verify 64-bit
  if (.Machine$sizeof.pointer != 8) {
    stop("Unable to install synapseclient on this platform.",
         "Binary installation is only available for 64-bit platforms.")
  }

  method <- match.arg(method)

  # some special handling for windows
  if (is_windows()) {

    # conda is the only supported method on windows
    method <- "conda"

    # confirm we actually have conda - let reticulate prompt miniconda installation
    have_conda <- !is.null(tryCatch(conda_binary(conda), error = function(e) NULL))
    if (!have_conda) {
      stop("synapseclient installation failed (no conda binary found)\n\n",
           "Install Miniconda by running `reticulate::install_miniconda()` or ",
           "install Anaconda for Python 3.x (https://www.anaconda.com/download/#windows) ",
           "before installing Tensorflow.\n",
           call. = FALSE)
    }

    # avoid DLL in use errors
    if (py_available()) {
      stop("You should call install_synapseclient() only in a fresh ",
           "R session that has not yet initialized synapseclient (this is ",
           "to avoid DLL in use errors during installation)")
    }
  }

  packages <- unique(c(
    parse_synapseclient_version(version),
    as.character(extra_packages)
  ))

  # don't double quote if packages were shell quoted already
  packages <- shQuote(gsub("[\"']", "", packages))

  # message("Installing the python pip packages :\n",
  # paste("  -", packages, collapse = "\n"))

  reticulate::py_install(
    packages       = packages,
    envname        = envname,
    method         = method,
    conda          = conda,
    python_version = python_version,
    pip            = TRUE,
    pip_ignore_installed = pip_ignore_installed,
    ...
  )

  cat("\nInstallation complete.\n\n")

  if (restart_session &&
      requireNamespace("rstudioapi", quietly = TRUE) &&
      rstudioapi::hasFun("restartSession"))
    rstudioapi::restartSession()

  invisible(NULL)
}


default_version <- numeric_version("2.5")

parse_synapseclient_version <- function(version) {
  # returns unquoted string directly passable to pip, e.g 'tensorflow==2.5.*'

  if(is.null(version) || is.na(version) || version %in% c("", "release"))
    return("synapseclient")

  version <- as.character(version) # if numeric_version()

  # full path to whl.
  if (grepl("^.*\\.whl$", version))
    return(normalizePath(version))

  if (grepl("nightly", version)) {
    if(!startsWith(version, "tf-"))
      version <- paste0("tf-", version)
    return(version)
  }

  package <- "synapseclient"
  if(grepl(".*(cpu|gpu)$", version)) {
    # append {-cpu,-gpu} suffix to package
    package <- sprintf("%s-%s", package, sub(".*-(cpu|gpu)$", "\\1", version))

    # strip -?{cpu,gpu} suffix from version
    version <- sub("(.*?)-?([cg]pu)$", "\\1", version)
  }

  if(version %in% c("default", ""))
    version <- default_version

  if(!grepl("[><=]", version))
    version <- sprintf("==%s.*", version)

  paste0(package, version)
}
