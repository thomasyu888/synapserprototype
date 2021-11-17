
#' synapseclient for R
#'
#' \href{https://www.tensorflow.org}{TensorFlow} is an open source software library
#' for numerical computation using data flow graphs. Nodes in the graph
#' represent mathematical operations, while the graph edges represent the
#' multidimensional data arrays (tensors) communicated between them. The
#' flexible architecture allows you to deploy computation to one or more CPUs or
#' GPUs in a desktop, server, or mobile device with a single API.
#'
#' The \href{https://www.tensorflow.org/api_docs/python/tf/all_symbols}{TensorFlow
#' API} is composed of a set of Python modules that enable constructing and
#' executing TensorFlow graphs. The tensorflow package provides access to the
#' complete TensorFlow API from within R.
#'
#' For additional documentation on the tensorflow package see
#' \href{https://tensorflow.rstudio.com}{https://tensorflow.rstudio.com}
#'
#' @import reticulate
#'
#' @docType package
#' @name tensorflow
NULL


# globals
.globals <- new.env(parent = emptyenv())
.globals$tensorboard <- NULL

.onLoad <- function(libname, pkgname) {

  # if TENSORFLOW_PYTHON is defined then forward it to RETICULATE_PYTHON
  synapseclient_python <- Sys.getenv("SYNAPSECLIENT_PYTHON", unset = NA)
  if (!is.na(synapseclient_python))
    Sys.setenv(RETICULATE_PYTHON = synapseclient_python)

  # honor option to silence cpp startup logs (INFO, level 1),
  # but insist on printing warnings (level 2) and errors (level 3)
  # cpp_log_opt <- getOption("tensorflow.core.cpp_min_log_level")
  # if (!is.null(cpp_log_opt))
  #   Sys.setenv(TF_CPP_MIN_LOG_LEVEL = max(min(cpp_log_opt, 1), 0))

  # delay load tensorflow
  syn <<- import("synapseclient", delay_load = list(

    priority = 5,

    environment = "r-reticulate",

    on_load = function() {

      # register warning suppression handler
      # register_suppress_warnings_handler(list(
      #   suppress = function() {
      #     if (tf_v2()) {
      #       tf_logger <- tf$get_logger()
      #       logging <- reticulate::import("logging")
      #
      #       old_verbosity <- tf_logger$level
      #       tf_logger$setLevel(logging$ERROR)
      #       old_verbosity
      #     } else {
      #       old_verbosity <- tf$logging$get_verbosity()
      #       tf$logging$set_verbosity(tf$logging$ERROR)
      #       old_verbosity
      #     }
      #   },
      #   restore = function(context) {
      #     if (tf_v2()) {
      #       tf_logger <- tf$get_logger()
      #       tf_logger$setLevel(context)
      #     } else {
      #       tf$logging$set_verbosity(context)
      #     }
      #   }
      # ))

      # if we loaded tensorflow then register tf help handler
      register_syn_help_handler()

      # workaround to silence crash-causing deprecation warnings
      # tryCatch(syn$python$util$deprecation$silence()$`__enter__`(),
      #          error = function(e) NULL)

      # TODO: move this into .onAttach, where you either emit immediately if
      # already loaded otherwise register emit hook for reticulate
      emit <- get("packageStartupMessage") # R CMD check
      # emit("Loaded synapseclient version ", syn$version$VERSION)
    }
    ,

    on_error = function(e) {
      stop(syn_config_error_message(), call. = FALSE)
    }

  ))

  # provide a common base S3 class for tensors
  # reticulate::register_class_filter(function(classes) {
  #   if (any(c("tensorflow.python.ops.variables.Variable",
  #             "tensorflow.python.framework.ops.Tensor",
  #             "tensorflow.python.ops.ragged.ragged_tensor.RaggedTensor")
  #           %in%
  #           classes)) {
  #     c("tensorflow.tensor", classes)
  #   } else {
  #     classes
  #   }
  # })

}



#' TensorFlow configuration information
#'
#' @return List with information on the current configuration of TensorFlow.
#'   You can determine whether TensorFlow was found using the `available`
#'   member (other members vary depending on whether `available` is `TRUE`
#'   or `FALSE`)
#'
#' @keywords internal
#' @export
syn_config <- function() {

  # first check if we found synapseclient
  have_synapseclient <- py_module_available("synapseclient")

  # get py config
  config <- py_config()

  # found it!
  if (have_synapseclient) {

    # get version
    version_raw <- syn$`__version__`

    tfv <- strsplit(version_raw, ".", fixed = TRUE)[[1]]
    version <- package_version(paste(tfv[[1]], tfv[[2]], sep = "."))

    structure(class = "synapseclient_config", list(
      available = TRUE,
      version = version,
      version_str = version_raw,
      location = config$required_module_path,
      python = config$python,
      python_version = config$version
    ))

    # didn't find it
  } else {
    structure(class = "synapseclient_config", list(
      available = FALSE,
      python_versions = config$python_versions,
      error_message = tf_config_error_message()
    ))
  }
}


#' @rdname tf_config
#' @keywords internal
#' @export
syn_version <- function() {
  config <- syn_config()
  if (config$available)
    config$version
  else
    NULL
}

#' @export
print.syn_config <- function(x, ...) {
  if (x$available) {
    aliased <- function(path) sub(Sys.getenv("HOME"), "~", path)
    cat("synapseclient v", x$version_str, " (", aliased(x$location), ")\n", sep = "")
    cat("Python v", x$python_version, " (", aliased(x$python), ")\n", sep = "")
  } else {
    cat(x$error_message, "\n")
  }
}

# Build error message for TensorFlow configuration errors
syn_config_error_message <- function() {
  message <- "Valid installation of TensorFlow not found."
  config <- py_config()
  if (!is.null(config)) {
    if (length(config$python_versions) > 0) {
      message <- paste0(message,
                        "\n\nPython environments searched for 'tensorflow' package:\n")
      python_versions <- paste0(" ", normalizePath(config$python_versions, mustWork = FALSE),
                                collapse = "\n")
      message <- paste0(message, python_versions, sep = "\n")
    }
  }

  python_error <- tryCatch({
    import("tensorflow")
    list(message = NULL)
  },
  error = function(e) {
    on.exit(py_clear_last_error())
    py_last_error()
  })

  message <- paste0(message,
                    "\nPython exception encountered:\n ",
                    python_error$message, "\n")

  message <- paste0(message,
                    "\nYou can install TensorFlow using the install_tensorflow() function.\n")
  message
}
