\name{makeJQRedis}
\alias{makeJQRedis}
\title{Instantiate a new JobQueue}
\description{Creates a new JobQueue.
For more information on JobQueues, see the \code{JobQueue-class} and
  \code{jobQueue-package} help files}
\usage{jq <- makeJQRedis(id=bmuuid(), host = "localhost", port = 6379, ...)} 
\arguments{
    \item{id}{A character string that uniquely identifies the queue to the
      Redis server and JQWorkers}
    \item{host}{The IP address of the machine running the Redis server}
    \item{port}{The Redis server port number}
}
\details{
If no id is given, the id is a random value returned by the function
\code{bmuuid}.

For more information on JobQueues, see the \code{\link{JobQueue-class}} help
file.
}
\examples{
## 1. Open one or more 'worker' R sessions and run:
require(jobQueue)
startJQWorkers(n=2, queue='jq1')

## 2. Open another R session acting as a 'master' and create these simple jobs
jq <- makeJQRedis(id='jq1')
joblist <- lapply(1:2, function(i) makeJob(key=paste0('testJob',i), expr=\{Sys.sleep(1); runif(1)\}))
sendJobs(jq, joblist)
getResults(jq, keys=c('testJob1', 'testJob2'), blocking=TRUE) #Will take a few seconds!
removeQueue(jq)
}

