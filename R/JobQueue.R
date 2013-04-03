#' A virtual reference class that represents a job queue.
#'
#' @export
#
#
JobQueue = setRefClass(
  Class="JobQueue",
  contains = "VIRTUAL",
  fields = list(
    id="character",
    waiting = "list", 
    inProgress="list", 
    results="list"),
  methods = list(
    initialize = function(id, ...){
      id <<- as.character(id)
      initFields(...)
    },
    
    send = function(jobs) {
      "add a job or list of jobs to the queue"
      if (!is.list(jobs)) {
        if(inherits(jobs, "Job")){
          jobs <- list(jobs)
          names(jobs) <- sapply(jobs, '[[', 'key')
        } else {
          stop("jobs argument must be a Job or a list of jobs")
        }
      }
      if (any(!sapply(jobs, inherits, "Job"))) {
        stop("jobs argument must be a Job or a list of jobs")
      }
      if(is.null(names(jobs))) {
        names(jobs) <- sapply(jobs, '[[', 'key')
      } else {
        if(any(names(jobs) != sapply(jobs, '[[', 'key'))) {
          warning("Names of jobs are not the same as the job keys. Names will be ignored in send(jobs)")
        }
      }
      jobs = jobs[setdiff(names(jobs), c(names(waiting), names(inProgress), names(results)))]
      waiting <<- c(waiting, jobs)
      names(jobs)
    },
    
    getResults = function(keys=NULL) {
      if(is.null(keys)) {
        ret <- results
      } else {
        ret <- results[intersect(keys, names(results))]
      }
      results <<- results[setdiff(names(results), names(ret))]
      return(ret)
    },
    
    keyStatus = function(keys) {
      status <- rep(as.character(NA),length(keys))
      names(status) <- keys
      status[keys %in% names(waiting)] = "waiting"
      status[keys %in% names(inProgress)] = "inProgress"
      status[keys %in% names(results)] = "complete"
      status
    },
    
    jobStatus = function(jobs) {
      if( !is.list(jobs)) jobs=list(jobs)
      keyStatus(sapply(jobs, getKey))
    },
    
    # Should be handed single job or list of jobs
    status = function(alist) {
      if( !is.list(alist)) alist=list(alist)
      status <- rep(as.character(NA),length(alist))
      isKey <- sapply(alist, is.character)
      isJob <- sapply(alist, is, "Job")
      if(!all(isJob | isKey)) {
        stop("Some elements in alist are not strings or Job objects:", which(!(isJob | isKey)))
      }
      if(any(isKey)){
        status[isKey] <- keyStatus(unlist(alist[isKey]))
      }
      if(any(isJob)){
        status[isJob] <- jobStatus(unlist(alist[isJob]))
      }
      status
    }
  )
)


#' A reference class that implements a job queue with a redis backend.
#' 
#' @export
JobQueueRedis = setRefClass(
    Class = "JobQueueRedis",
    contains = "JobQueue",
    fields = list(
      host = "character",
      port = "integer"
    ),
    methods = list(
      initialize = function(id=bmuuid(), host = "localhost", port = 6379, timeout = 67108863, ...) {
        redisConnect(host, port,timeout=timeout)
        ##TODO: fault tolerance fork
        callSuper(id=id, ...)
      },

      isKeyInQueue = function(key) {
          queueWaiting = paste(id, 'waiting', sep=':')
          queueInProgress = paste(id, 'inProgress', sep=':')
          queueDone = paste(id, 'done', sep=':')
          jobsInQueue <- redisSUnion(queueWaiting, queueInProgress, queueDone)
          return(key %in% jobsInQueue)
      },
      
      send = function(jobs, ...) {
        if(length(jobs) == 1) jobs=list(jobs)
        dots <- list(...)
        if(length(dots)) jobs = append(jobs, dots)  
        for(jb in jobs) {
          if(class(jb) == 'Job') {
            jobNumDepends = paste(id, jb$key, 'numWaitingOn', sep=':')
            jobDepends = paste(id, jb$key, 'Dependancies', sep=':')
            jobEnv = paste(id, jb$key, 'env', sep=':')
            queueWaiting = paste(id, 'waiting', sep=':')
            queueDone = paste(id, 'done', sep=':')
            if(!isKeyInQueue(jb$key)) {
              redisSetBlocking(FALSE)
              if(length(jb$dependsOn)) {
                for (i in jb$dependsOn) {
                  redisSAdd(jobDepends,i)
                }
                redisSDiffStore(jobDepends, jobDepends, queueDone)
              } 
              redisGetResponse()
              redisSetBlocking(TRUE)
              numDeps = redisSCard(jobDepends)
              if(numDeps > 0) redisDelete(jobDepends)
              redisSetBlocking(FALSE)
              redisIncrBy(jobNumDepends, numDeps)
              for (i in jb$dependsOn) {
                redisSAdd(paste(id, i, 'Dependees', sep=':'), jb$key)
              }
              redisSet(jobEnv, jb)
              redisSAdd(queueWaiting, jb$key)
              redisRPush(id, jb$key)
              redisGetResponse()
              redisSetBlocking(TRUE)
            } else {
              warning('Job with key ', jb$key, ' is already in this queue.  No action taken.')
            }
          } else {
            warning('One or more arguments were not Job objects and were not sent.')
          }
        }
      },
     
      getResults = function(keys = NULL, blocking = FALSE, removeFinished = FALSE, restartFaults = TRUE, verbose=FALSE) {
        # Returns null if key is not done yet.
        queueDone = paste(id, 'done', sep=':')
        if(is.null(keys)) {
          keys = redisSMembers(queueDone)
        }
        keys = unlist(keys)
        queueOut = paste(id, keys, 'out', sep=':')
        res = lapply(queueOut, function(i) {
            if( blocking ) {
              res = redisBLPop(i)
            } else {
              res = redisLPop(i)
            }
            if (!removeFinished) {
              redisRPush(i, res)
            }
            res
          })
        names(res) = keys
        if(length(res) == 1 && is.null(res[[1]])) res<-list()
        if(removeFinished){
          lapply(keys, function(k) invisible(redisSRem(queueDone, k)))
        }
        # Check for failed workers
        ftcheck(id=id, restartFaults=restartFaults, verbose=verbose)
        return(res)
      },
  
      getWaiting = function() {
        queueWaiting = paste(id, 'waiting', sep=':')
        return(redisSMembers(queueWaiting))
      },

      getInProgress = function() {
        queueInProgress = paste(id, 'inProgress', sep=':')
        return(redisSMembers(queueInProgress))
      }

    )
)
    

#######################
## S4-style interface to the JobQueue reference class
#######################

#getWaiting -- get keys of all jobs waiting to be processed
#' @export
setGeneric(
    name = "getWaiting",
    def=function(object){standardGeneric("getWaiting")}
)

setMethod(
  f = "getWaiting",
  signature = "JobQueue",
  definition = function(object) object$getWaiting()
)

#getInProgress -- get keys of all jobs currently running
#' @export
setGeneric(
    name = "getInProgress",
    def=function(object){standardGeneric("getInProgress")}
)

setMethod(
  f = "getInProgress",
  signature = "JobQueue",
  definition = function(object) object$getInProgress()
)


# getResults -- get all or a subset of results back from workers
#' @export
setGeneric(
    name = "getResults",
    def=function(object, keys=NULL, blocking=FALSE, removeFinished = FALSE, restartFaults = TRUE, verbose=FALSE){standardGeneric("getResults")}
#    def=function(object, keys=NULL){standardGeneric("getResults")}
)

setMethod(
  f = "getResults",
  signature = "JobQueue",
#  definition = function(object,keys) object$getResults(keys)
  definition = function(object, keys, blocking, removeFinished, restartFaults, verbose) object$getResults(keys=keys, blocking=blocking, removeFinished=removeFinished, restartFaults=restartFaults, verbose=verbose)
)


# run the jobs in the queue (only needed for some types of job queues)
#' @export
#if(!isGeneric("run")) setGeneric(
#    name = "run",
#    def=function(object){standardGeneric("run")}
#)
#
#setMethod(
#  f = "run",
#  signature = "JobQueue",
#  definition = function(object) {object$run(); object}
#)

# run the jobs in the queue (only needed for some types of job queues)
#' @export
if(!isGeneric("sendJobs")) setGeneric(
    name = "sendJobs",
    def=function(queue, jobs, ...){standardGeneric("sendJobs")}
)

setMethod(
  f = "sendJobs",
  signature = "JobQueue",
  definition = function(queue, jobs, ...) queue$send(jobs=jobs, ...)
)


#' @export
makeJQRedis = function(id = bmuuid(), host="localhost", port=6379,...) {
    JobQueueRedis$new(id=id, host=host, port=port, ...)
}

