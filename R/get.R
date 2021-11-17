#' Wraps syn.get Written for tests
#'
#' @param synid Synapse Id of an entity
.get <- function(synid) {
  if (!is.null(.syn)) {
    .syn$get(synid)
  }
}

#' Gets a Synapse entity
#'
#' @param synid Synapse Id of an entity
#'
#' @return Entity
#' @examples
#' library(synapserprototype)
#' entity <- get('syn123')
#' @import reticulate
#' @export
get <- function(synid) {
  .get(synid)
}
