\name{jobQueue-package}
\alias{jobQueue-package}
\alias{jobQueue}
\docType{class}
\title{
A non-blocking job queue implementation for R using Redis
}
\description{
    This help page gives an overview of the jobQueue package.  The package
    borrows heavily from the doRedis package by B.W. Lewis.

    The jobQueue package provides an interface to an arbitrarily large parallel
    backend (on a Redis server, not provided) that enables the simultaneous
    execution of multiple jobs and the creation of jobs that only run when the
    jobs they depend on are finished.  
}

\details{
    The jobQueue package in practice consists of Jobs, a JobQueue and 
    jobQueueWorkers.

    A Job is an object holding an unevaluated R expression, which can include
    other parallel functions, e.g. a call to foreach using doRedis. For more
    information on Jobs, see the \code{\link{Job}} help file.

    A JobQueue is essentially the frontend of a job queue implemented in Redis
    (a connection to an available Redis server is required, and not included as
    part of this package). The queue tracks jobs before, during and after
    evaluation, and holds the result of the job when it is finished. For more
    information on JobQueues, see the \code{\link{JobQueue}} help file.

    A jqWorker is a process that polls the job queue for available jobs and
    runs one whenever whenever it can, returning the result to the job queue
    when finished. There can be an arbitrary number of worker processes on an
    arbitrary number of machines, as long as they can connect to the master (on
    which the jobs and queue were created). For more information on jqWorkers,
    see the \code{\link{startJQWorkers}} help file.
}

\author{
  \describe{
    \item{Luke Moryl}{\email{lsmoryl@pivotaltargeting.com}}
    \item{Peter Foley}{\email{pwfoley@pivotaltargeting.com}}
  }
}

\section{jobQueue applications}{
}

\note{
  Many of the components of the jobQueue package require network access to a
  Redis server.  Note that multiple JobQueues and multiple doRedis queues can
  exist on a single Redis server, provided that the JobQueues have distinct ids
  and, likewise, that the doRedis queues have distinct queue names.

\examples{
\dontrun{
# The example assumes that a Redis server is running on the local host
# and standard port.

require('jobQueue')
startJQWorkers(n=2, queue='jq')
# 'jq' is the name that identifies the queue.  In general, it may be good
# practice to give the queue the same id and name in the R namespace.

# 2. Open another R session acting as a 'master' and run this simple
#    sampling approximation of pi:
require('jobQueue')
exampleJQ <- makeRedisJQ(id = 'jq')
jobList = sapply(paste0('job',1:2), function(j) {Job$new(key=j, expr=
      {
        foreach(j=1:10,.combine=sum,.multicombine=TRUE) \%dopar\%                                                                                                                                 
        4*sum((runif(1000000)^2 + runif(1000000)^2)<1)/10000000     
      }
)})
dependentJob = Job$new(key='job3', dependsOn = c('job1', 'job2'), expr = 
  {
    oldResults <- getResults(exampleJQ)
    newResult = (oldResults$job1 + oldResults$job2)/2
  }
)
sendJobs(exampleJQ, c(jobList, dependentJob))
getResults(exampleJQ, keys='job3', blocking=TRUE)
}
}
