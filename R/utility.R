#' Function to load an RData file into a list
#'
#' @param file .RData file to be loaded
#' @export
load.as.list = function(file){
   env = new.env()
   load(file, envir=env)
   as.list(env)
}

#' Function to check if all workers assigned to a given queue are still running
#'
#' @param q the queue whose workers we are checking
#' @export
ftcheck = function(id, restartFaults=TRUE, verbose=FALSE) {
  queueStart <- paste(id,"start",sep=":")
  queueStart <- paste(queueStart, "*", sep=":")
  queueAlive <- paste(id,"alive",sep=":")
  queueAlive <- paste(queueAlive, "*", sep=":")
  queueWaiting = paste(id, 'waiting', sep=':')
  queueInProgress = paste(id, 'inProgress', sep=':')

  started <- redisKeys(queueStart)
  started <- sub(paste(id,"start","",sep=":"),"",started)
  alive <- redisKeys(queueAlive)
  alive <- sub(paste(id,"alive","",sep=":"),"",alive)
  fault <- setdiff(started,alive)

  if(length(fault)>0) {
    if(verbose) cat('faults on jobs:', fault, '\n')
    if(restartFaults) {
      for(resub in fault) {
        redisSRem(queueInProgress, resub)
        redisSAdd(queueWaiting, resub)
        redisDelete(paste(id, 'start', resub, sep=':'))
        redisRPush(id, resub)
      }
    }
  }
}


#' function to draw a random int
randomInt = function(n) as.integer(floor(runif(n, -2^31+1, 2^31)))


#' function to call methods of a list of reference classes or S3/S4 objects
#' @export
refApply = function(alist, f, ...) {
  lapply(alist, function(o) {
    if(inherits(o, "envRefClass")) {
      args = list(x=o, name=f)
      do.call('$', args)(...)
    } else {
      args = list(o, ...)
      do.call(f, args)
    }
  })
}


#' alternative uuid generator that works whether synchronicity is available or not
#' @export
bmuuid = function() {
  tryCatch(bmuuid(), error=function(e) gsub('[/\\:]','',tempfile()))
}

