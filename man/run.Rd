\name{runJob}
\alias{runJob}
\title{Evaluates a Job's expression in its environment}
\description{For more information on Jobs, see the \code{Job-class} and
  \code{jobQueue-package} help files}
\usage{runJob(jb)}
\details{
The first time runJob() is called on a Job, it evaluates the expression within
the Job's environment.  Future calls simply return the stored result from
the first evaluation.

This function is used implicitly by worker machines connected to a JobQueue,
and outside of making sure one understands how Jobs work there is no real
reason for the user to invoke it directly.
}
\examples{
var1 = 1
jb <- runJob(expr=1+var1)
runJob(jb)
}


