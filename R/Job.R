#' An S4 class that represents a job.
#'
#' @slot env an environment containing any variables used in the expression
#' @slot expr an expression to be run
#' @slot packages that need to be loaded before running expr. Packages that are not installed in .libPaths should be referenced by full installation path
#' @seed an integer vector that can be assigned to .Random.seed OR an integer that can be passed to set.seed
#' @export
Job <- setRefClass(
    Class = "Job",
    fields = list( key = "character", 
      envir = "list", 
      expr = "ANY", 
      packages = "character", 
      seed = "integer", 
      dependsOn = "character",
      .exportenv = "environment"),
    methods = list(
      run = function() {"runs the job"
        # set the random seed
        oldseed <- NULL
        if(length(seed) > 0){
          if(!exists('.Random.seed')) runif(1) # initialize the RNG if needed
          oldseed <- .Random.seed
          if(length(seed) == 1) {
            set.seed(seed)
          } else {
            # use assign to avoid warnings about non-local assignment
            assign('.Random.seed', oldseed, globalenv())
          }
        }
        
        # load packages as needed
        for(p in packages) {
          if(dirname(p) == '.') {
            library(package=p, character.only=T)
          } else {
            library(package=basename(p), character.only=T, lib.loc=dirname(p))
          }
        }
        
        # run the job
        result <- tryCatch({
            eval(expr = expr, envir = list2env(envir))
          }, error = function(e) e
        ) 
        
        # set the random seed back to where it was if necessary
        if(!is.null(oldseed)) assign('.Random.seed', oldseed, globalenv())
        
        return(result)
      },
      
      initialize = function(expr, envir=parent.frame(n=4), key=bmuuid(), noexport=character(), verbose=FALSE, export=character(), ...) {
# Setup the parent environment by first attempting to create an environment
# that has '...' defined in it with the appropriate values
        .makeDotsEnv <- function(...) {
          list(...)
          function() NULL
        }
        # allow lists as environment arguments
        if(is.environment(envir)){
          envir <<- as.list(envir)
        } else if(is.list(envir)){
          envir <<- envir
        } else {
          stop("envir must be a list or environment")
        }
        rm(envir) # ensure that it searches down to the object environment rather than hitting the function argument
        print(unlist(envir))
        
        # set up expr
        expr <<- substitute(expr)
        rm(expr) # remove function-local version so later usage hits the object environment

        ############
#        .exportenv <<- tryCatch({
#          qargs <- quote(list(...))
#          args <- eval(qargs, envir)
#          environment(do.call(.makeDotsEnv, args))
#        },
#        error=function(e) {
#          new.env(parent=emptyenv())
#        })
        #foreach::getexports(expr, exportenv, envir, bad=noexport)
        #exportenv = NULL
        ############
        vars <- names(envir)
        if (verbose) {
          if (length(vars) > 0) {
            cat('automatically exporting the following objects',
                'from the local environment:\n')
            cat(' ', paste(vars, collapse=', '), '\n')
          } else {
            cat('no objects are automatically exported\n')
          }
        }
# Compute list of variables to export
        #ignore <- intersect(export, vars)
        #if (length(ignore) > 0) {
        #  warning(sprintf('already exporting objects(s): %s',
        #          paste(ignore, collapse=', ')))
        #  export <- setdiff(export, ignore)
        #}
# Add explicitly exported variables to exportenv
        #if (length(export) > 0) {
        #  if (verbose)
        #    cat(sprintf('explicitly exporting objects(s): %s\n',
        #                paste(export, collapse=', ')))
        #  for (sym in export) {
        #    if (!exists(sym, envir, inherits=TRUE))
        #      stop(sprintf('unable to find variable "%s"', sym))
        #    assign(sym, get(sym, envir, inherits=TRUE),
        #           pos=exportenv, inherits=FALSE)
        #  }
        #}
        #envir <<- exportenv
        # Danger!  Might not always work in future versions of R
        #parent.env(envir) <<- parent.frame()
        
        initFields(key=key, ...)
      },
      
      depDone = function(keys) {
        dependsOn <<- setdiff(dependsOn, keys)
      }
    )
)


Job$accessors('key','expr','envir','dependsOn','packages')

# S4-style methods for Job objects
#' @export
if(!isGeneric("getKey")) setGeneric(
    name = "getKey",
    def=function(object){standardGeneric("getKey")}
)

setMethod(
  f="getKey",
  signature = "Job",
  definition = function(object) object$getKey()
)

#' @export
if(!isGeneric("getDependsOn")) setGeneric(
    name = 'getDependsOn',
    def=function(object) {standardGeneric('getDependsOn')}
)

setMethod(
  f='getDependsOn',
  signature='Job',
  definition = function(object) object$getDependsOn()
)

#' @export
setGeneric(
    name = "run",
    def=function(object){standardGeneric("run")}
)

setMethod(
  f="run",
  signature = "Job",
  definition = function(object) object$run()
)



# job that can be safely serialized and run elsewhere
setClass("ExternalJob",
    representation = representation(envir = "environment", expr = "ANY", packages = "character", key = "character", seed="integer")
)


setMethod(
    f = "run",
    signature = "ExternalJob",
    definition = function(object) {
        oldseed = NULL
        for(p in object@packages) library(package=p, character.only=TRUE)
        if(length(object@seed)>0){
          oldseed = .Random.seed
          if(length(object@seed)==1) {
            set.seed(object@seed)
          } else {
            .Random.seed = object@seed
          }
        }
        
        result = list(eval(expr = object@expr, envir = object@envir))
        names(result) = object@key
        if(!is.null(oldseed)) .Random.seed = oldseed
        return(result)
    }
)

setMethod(
    f="getDependsOn",
    signature = "ExternalJob",
    definition = function(object) object@dependsOn
)

setMethod(
    f = "getKey",
    signature = "ExternalJob",
    definition = function(object) object@key
)


Job$methods(
  makeExternal = function(){
    new("ExternalJob", envir=envir, expr=expr, packages=packages, seed=seed, key=key)
  }
)

