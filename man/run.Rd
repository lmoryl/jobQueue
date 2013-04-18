\name{run}
\alias{run}
\title{Evaluates a Job's expression in its environment}
\description{For more information on Jobs, see the \code{Job-class} and
  \code{jobQueue-package} help files}
\usage{run(jb)}
\details{
The first time run() is called on a Job, it evaluates the expression within
the Job's environment.  Future calls simply return the stored result from
the first evaluation.

This function is used implicitly by worker machines connected to a JobQueue,
and outside of making sure one understands how Jobs work there is no real
reason for the user to invoke it directly.
}
\example{
var1 = 1
jb <- run(expr=1+var1)
run(jb)
}


