\name{JobQueue-class}
\doctype{class}
\alias{JobQueue-class}
\alias{JobQueue}
\title{
A class that offers an interface to a job queue managed on Redis.
}
\description{
A JobQueue holds Jobs and their state--whether they are waiting for evaluation,
evaluating or finished evaluating.  A JobQueue is creaeted with
\code{\link{startJQRedis}}; Jobs can be added with \code{\link{sendJobs}}, and
results are retrieved with \code{\link{getResults}}.

Jobs in a JobQueue are processed by workers dedicated to that JobQueue (see
the help file for \code{\link{startJQWorkers}} for more information).

A JobQueue checks for faults and automatically resubmits failed
tasks whenever a job completes evaluation on a worker machine and whenever
getResults is called on the JobQueue.
}
\section{fields}{
  \describe{
    \item{id}{A character string that uniquely identifies the queue to the
      Redis server and JQWorkers}
    \item{host}{The IP address of the machine running the Redis server}
    \item{port}{The Redis server port number}
}} 
\section{Methods}{
  \describe{
    \item{makeJQRedis}
    \item{sendJobs}
    \item{getWaiting}
    \item{getInProgress}
    \item{getResults}
  }
}
\author{
Luke Moryl <lsmoryl@pivotaltargeting.com>
Peter Foley <pwfoley@pivotaltargeting.com>
}
\note{
All JobQueue functions require network access to a Redis server (not
included with the JobQueue package).
}


