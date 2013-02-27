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
ftcheck = function(queue) {
if(FALSE){
  queueStart <- paste(queue,"start", sep=":")
  queueStart <- paste(queueStart, "*", sep="")
  queueAlive <- paste(queue,"alive", sep=":")
  queueAlive <- paste(queueAlive, "*", sep="")

# Check for worker fault and re-submit tasks if required...
  started <- redisKeys(queueStart)
  started <- sub(paste(queue,"start","",sep=":"),"",started)
  alive <- redisKeys(queueAlive)
  alive <- sub(paste(queue,"alive","",sep=":"),"",alive)
  fault <- setdiff(started,alive)
  if(length(fault)>0) { 
# One or more worker faults have occurred. Re-sumbit the work.
#    fault <- paste(queue, "start", fault, sep=":")
#    fjobs <- redisMGet(fault)
#    redisDelete(fault)
#    for(resub in fjobs) {
#      block <- argsList[unlist(resub)]
#      names(block) <- unlist(resub)
#      if (obj$verbose)
#        cat("Worker fault: resubmitting jobs", names(block), "\n")
#      redisRPush(queue, list(ID=ID, argsList=block))
#    }
     redisSRem(queueInProgress, fault)
     redisSAdd(queueWaiting, fault)
     for(resub in fault) redisRPush(queue, resub)
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

