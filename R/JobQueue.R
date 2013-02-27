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


#' A reference class that implements a job queue with mcparallel.
#' Starts running jobs as soon as possible.
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
      initialize = function(host = "localhost", port = 6379,...) {
        redisConnect(host, port)
        ##TODO: fault tolerance fork
        callSuper(...)
      },
      
      send = function(jb) {
        jobDepends = paste(id, jb$key, 'waitingOn', sep=':')
        jobEnv = paste(id, jb$key, 'env', sep=':')
        queueWaiting = paste(id, 'waiting', sep=':')

        #redisSetBlocking(FALSE)
        redisSet(jobDepends, length(jb$dependsOn))
        for (i in jb$dependsOn) {
          redisSAdd(paste(id, i, 'Dependees', sep=':'), jb$key)
        }
        redisSet(jobEnv, jb)
        redisSAdd(queueWaiting, jb$key)
        redisRPush(id, jb$key)
        #redisSetBlocking(TRUE)
      },
     
      getResults = function(keys = NULL) {
        # Returns null if key is not done yet.
        if(is.null(keys)) {
          queueDone = paste(id, 'done', sep=':')
          keys = redisSMembers(queueDone)
        }
        keys = unlist(keys)
        queueOut = paste(id, keys, 'out', sep=':')
        res = lapply(queueOut, redisGet)
        names(res) = keys
        # Check for failed workers
        ftcheck(id)
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

# getResults -- get all or a subset of results back from workers
#' @export
setGeneric(
    name = "getResults",
    def=function(object, keys=NULL){standardGeneric("getResults")}
)

setMethod(
  f = "getResults",
  signature = "JobQueue",
  definition = function(object, keys) object$getResults(keys)
)


# run the jobs in the queue (only needed for some types of job queues)
#' @export
if(!isGeneric("run")) setGeneric(
    name = "run",
    def=function(object){standardGeneric("run")}
)

setMethod(
  f = "run",
  signature = "JobQueue",
  definition = function(object) {object$run(); object}
)

#' @export
sendJobs = function(queue, jobs) {
    if(length(jobs) > 0) {
      if(length(jobs) == 1) jobs = list(jobs)
      sapply(jobs, function(i) queue$send(i))
    } 
}

#' @export
makeJobQueueRedis = function(id = bmuuid(), host="localhost", port=6379,...) {
    JobQueueRedis$new(id=id, host=host, port=port, ...)
}

