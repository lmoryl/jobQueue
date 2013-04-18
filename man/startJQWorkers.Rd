\name{startJQWorkers}
\alias{startJQWorkers}
\title{
startJQWorkers
}
\description{
Start background R jobQueue worker processes on the local system.
}
\usage{
startJQWorkers(n, queue, host = "localhost", port = 6379, iter = Inf, timeout = 60, log = stdout(),  Rbin = paste(R.home(component="bin"),"R",sep="/"))
}
\arguments{
  \item{n}{
The number of workers to start.
}
  \item{queue}{
A (character) job work queue id, or a list or character vector of queue ids.
}
  \item{host}{
The Redis server host name or (character) I. P. address.
}
  \item{port}{
The Redis server port number.
}
  \item{iter}{
The maximum number of jobs to execute before exiting the worker loop (defaults
to infinity).
}
  \item{timeout}{
The worker loop terminates if the work queue is deleted after the
specified timeout interval.
}
  \item{log}{
Log messages to the specified destination (defaults to stderr()).
}
  \item{Rbin}{
The full path to the command-line R program.
}
}
\details{
Use \code{startJQWorkers} to start one or more jobQueue R worker processes
in the background. The worker processes are started on the local system using
the \code{redisWorker} function.

Running workers self-terminate when their work queues are deleted with the
\code{removeQueue} function.  They also terminate if a keyboard interrupt
is received in the R session.
}
\value{
Nothing is returned. Set the \code{log} parameter to \code{stdout()} to
see log messages printed on standard output of the invoking R session.
}
\author{
Luke Moryl <lsmoryl@pivotaltargeting.com>
Peter Foley <pwfoley@pivotaltargeting.com>
}
\note{
JobQueue functions require network access to a Redis server (not
included with the doRedis package).
}

\seealso{
\code{\link{makeJQRedis}}
\code{\link{jqWorker}}
}
\examples{
\dontrun{
## 1. Open one or more 'worker' R sessions and run:
require(jobQueue)
startJQWorkers(n=2, queue='jq1')

## 2. Open another R session acting as a 'master' and create these simple jobs
jq <- makeJQRedis(id='jq1')
joblist <- lapply(1:2, function(i) makeJob(key=paste0('testJob',i), expr={Sys.sleep(1); runif(1)}))
sendJobs(jq, joblist)
getResults(jq, keys=c('testJob1', 'testJob2'), blocking=TRUE) #Will take a few seconds!
removeQueue(jq)
}
}
