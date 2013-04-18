\name{sendJobs}
\alias{sendJobs}
\title{
Send one or more Jobs to a JobQueue
}
\description{
Sends a Job, list of Jobs, or multiple lists of Jobs to the JobQueue's waiting
list.  This list is cycled through by any free workers and, if a waiting Job
has all dependencies finished (or no dependencies), the worker processing the
Job.
}
\usage{
sendJobs(queue, jobs, ...)
}
\arguments{
  \item{queue}{A JobQueue object.}
  \item{jobs}{A job or list of jobs.}
  \item{...}{Additional jobs or lists of jobs}
}
\value{
Returns TRUE if all jobs successfully sent to the queue or already in the
queue.  Returns false and possibly warnings otherwise.

If a job is already in the queue, the user is warned and no action is taken.
}
\author{
Luke Moryl <lsmoryl@pivotaltargeting.com>
Peter Foley <pwfoley@pivotaltargeting.com>
}
\note{
JobQueue functions require network access to a Redis server (not
included with the doRedis package).
}

