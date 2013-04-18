\name{jqWorker}
\alias{jqWorker}
\title{
jqWorker
}
\description{
Initialize a jobQueue worker R process.
}
\usage{
jqWorker(queue, host = "localhost", port = 6379, iter = Inf, timeout = 30, log = stdout())
}
\arguments{
  \item{queue}{
A (character) job queue id, or a list or character vector of queue names.
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
Log messages to the specified destination (defaults to stdout()).
}
}
\details{
The jqWorker function enrolls the current R session in one or
more jobQueue worker pools specified by the job queue ids. The worker
loop takes over the R session until either the work queue(s) are deleted
or a keyboard interrupt is issued.
}
\value{
Nothing is returned but status messages are printed to the log
during operation of the worker loop.
}
\author{
B. W. Lewis <blewis@illposed.net>
}
\note{
All doRedis functions require network access to a Redis server (not
included with the doRedis package).
}

\seealso{
\code{\link{makeJQRedis}}
}
\examples{
\dontrun{
require('jobQueue')
jqWorker('jq')
}
}
