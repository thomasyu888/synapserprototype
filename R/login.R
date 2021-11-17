#' Logs into Synapse.
#'
#' @param email a Synapse username (optional, not required if .synapseConfig available)
#' @param password a Synapse password (optional, not required if .synapseConfig available)
#' @param apiKey Base64 encoded Synapse API key
#' @param rememberMe Whether the authentication information should be cached in your operating system's credential storage.
#' @param silent Defaults to False.  Suppresses the "Welcome ...!" message.
#' @param forced  Defaults to False.  Bypass the credential cache if set.
#' @param authToken A bearer authorization token, e.g. a personal access token, can be used in lieu of a password or apiKey
#' @examples
#' library(synapserprototype)
#' syn_login()
#' @import reticulate
#' @export
syn_login <- function(
  email=NULL,
  password=NULL,
  apiKey=NULL,
  rememberMe=F,
  silent=F,
  forced=F,
  authToken=NULL
) {
  .syn <<- synapseclient$Synapse()
  .syn$login(email=email,
             password=password,
             apiKey=apiKey,
             rememberMe=rememberMe,
             silent=silent,
             forced=forced,
             authToken=authToken)
}

#' Checks .syn object exists.
#' @returns A message.
#' @export
.check_login <- function(){
  if(!exists(".syn")){
    stop('Please run `synapserprototype::syn_login()` prior to running functions that require a connection to Synapse. (Alternatively, the Python `synapseclient` is unavailable.)')
  }else if(capture.output(.syn) == "<pointer: 0x0>"){
    stop('Please run `synapserprototype::syn_login()` prior to running functions that require a connection to Synapse. (Alternatively, the Python `synapseclient` is unavailable.)')
  }
}
