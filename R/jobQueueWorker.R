.jqRedisGlobals <- new.env(parent=emptyenv())

# .setOK and .delOK support worker fault tolerance
`.setOK` <- function(port, host, key)
{
  .Call("setOK", as.integer(port), as.character(host), as.character(key),PACKAGE="jobQueue")
  invisible()
}

`.delOK` <- function()
{
  .Call("delOK",PACKAGE="jobQueue")
  invisible()
}

`.jqWorkerInit` <- function(job, exportenv, packages, log)
{
# Override the function set.seed.worker in the exportenv to change!
  assign('job', job, .jqRedisGlobals)
#  assign('exportenv', exportenv, .jqRedisGlobals)
# XXX This use of parent.env should be changed. It's used here to
# set up a valid search path above the working evironment, but its use
# is fraglie as this may function be dropped in a future release of R.
#  parent.env(.jqRedisGlobals$exportenv) <- globalenv()
  tryCatch(
    {for (p in job$packages)
      library(p, character.only=TRUE)
    }, error=function(e) cat(as.character(e),'\n',file=log)
  )
}

`.jobEvalWrapper` <- function()
{
  tryCatch({
  #    lapply(names(args), function(n)
  #                       assign(n, args[[n]], pos=.doRedisGlobals$exportenv))
      eval(.jqRedisGlobals$job$run(), envir=.jqRedisGlobals$exportenv)
    },
    error=function(e) e
  )
}

`startLocalJQWorkers` <- function(n, queue, host="localhost", port=6379, iter=Inf, timeout=60, log=stdout(), Rbin=paste(R.home(component='bin'),"R",sep="/"))
{
  m <- match.call()
  f <- formals()
  l <- m$log
  if(is.null(l)) l <- f$log
  cmd <- paste("require(jobQueue);jqWorker(queue='",queue,"', host='",host,"', port=",port,", iter=",iter,", timeout=",timeout,", log=",deparse(l),")",sep="")
  j=0
  args <- c("--slave","-e",paste("\"",cmd,"\"",sep=""))
  while(j<n) {
#      system2(Rbin,args=args,wait=FALSE,stdout=NULL)
    system(paste(c(Rbin,args),collapse=" "),intern=FALSE,wait=FALSE)
    j = j + 1
  }
}

`jqWorker` <- function(queue, host="localhost", port=6379, iter=Inf, timeout=30, log=stdout())
{
  redisConnect(host,port)
  queueLive <- paste(queue,"live",sep=".")
  queueWaiting = paste(queue, 'waiting', sep=':')
  queueInProgress = paste(queue, 'inProgress', sep=':')
  queueDone = paste(queue, 'done', sep=':')
  for(j in queueLive)
  {
    if(!redisExists(j)) redisSet(j,NULL)
  }
  queueCount <- paste(queue,"count",sep=".")
  for(j in queueCount)
    tryCatch(redisIncr(j),error=function(e) invisible())
  cat("Waiting for jobs from the Job Queue.\n", file=log)
    flush.console()
  k <- 0
  while(k < iter) {
    work <- redisBLPop(queue, timeout=timeout)
    jbkey <- work[[1]]
    queueEnv <- paste(queue, jbkey, 'env', sep=":")
    flush.console()
    queueOut <- paste(queue, jbkey, 'out', sep=":")
# We terminate the worker loop after a timeout when all specified work
# queues have been deleted.
    if(is.null(work[[1]]))
     {
      ok <- FALSE
      for(j in queueLive) ok <- ok || redisExists(j)
      if(!ok) {
# If we get here, our queues were deleted. Clean up and exit worker loop.
        #for(j in queueOut) if(redisExists(j)) redisDelete(j)
        for(j in queueEnv) if(redisExists(j)) redisDelete(j)
        for(j in queueCount) if(redisExists(j)) redisDelete(j)
        for(j in queueInProgress) if(redisExists(j)) redisDelete(j)
        for(j in queue) if(redisExists(j)) redisDelete(j)
        break
      }
     }
    else
# Cycle through job keys til one shows up that doesn't have outstanding dependencies
     {

      jobDepends = paste(queue, jbkey, 'waitingOn', sep=':')
      numDependencies = redisGet(jobDepends)
      ##TODO: put in function to see job's dependency count.  If ever less than 0, that's a bug and shouldn't be ignored.
      if( numDependencies != 0 ) redisRPush(queue, jbkey)
      else { 
# We've found a job we can run.      
        k <- k + 1
        cat("Processing task",jbkey,"from queue",names(work),"\n",file=log)
        flush.console()
        redisSRem(queueWaiting, jbkey)
        redisSAdd(queueInProgress, jbkey)
        initdata = redisGet(queueEnv);
        .jqWorkerInit(initdata, initdata$envir, initdata$packages, log)
        fttag.start <- paste(queue,"start",jbkey,sep=":")
        fttag.alive <- paste(queue,"alive",jbkey,sep=":")
# fttag.start is a permanent key
# fttag.alive is a matching ephemeral key that is regularly kept alive by the
# setOK helper thread. Upon disruption of the thread (for example, a crash),
# the resulting Redis state will be an unmatched start tag, which may be used
# by fault tolerant code to resubmit the associated jobs.
        redisSet(fttag.start,1)
        .setOK(port, host, fttag.alive)
#        result = .jobEvalWrapper()
        result = .jqRedisGlobals$job$run()
        redisSet(queueOut, result)
        redisSRem(queueInProgress, jbkey)
        redisSAdd(queueDone, jbkey)
        redisDelete(jobDepends)
        redisDelete(queueEnv)
# Fault tolerance:  currently, check each time job completes for failed workers
        ftcheck(queue)
        #redisSAdd(queueFinished, jbkey)
        tryCatch(redisDelete(fttag.start), error=function(e) invisible())
        .delOK()
      }
    }
  }
# Either the queue has been deleted, or we've exceeded the number of
# specified work iterations.
  for(j in queueCount) if(redisExists(j)) redisDecr(j)
  cat("Worker exit.\n", file=log)
  redisClose()
}



