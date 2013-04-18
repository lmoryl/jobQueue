\name{makeJob}
\alias{makeJob}
\title{Instantiate a new Job}
\description{For more information on Jobs, see the \code{Job-class} and
  \code{jobQueue-package} help files}
\usage{j <- makeJob(key, expr, envir, packages, seed, dependsOn, export, noexport)}
\arguments{
    \item{key}{A character string that identifies the job within a job queue}
    \item{expr}{Any valid R expression}
    \item{envir}{An R environment or list of variable assignments.  If not
      specified, an environment is created containing all variables in expr
      that exist in the environment in which the Job is created.}
    \item{packages}{A character vector containing Jobs required for the expr
      to be evaluated in a new R session}
    \item{seed}{An integer seed that is set before expr's evaluation}
    \item{dependsOn}{A list of keys of Jobs that this Job depends on.  These
      should be jobs that must be complete before expr can be evaluated.}
}
\details{
If no key is given, the key is a random value returned by the function
\code{bmuuid}.

envir can be passed as a list or an environment; if none is specified, it is
taken from the calling environment.
}
\example{
var1 = 1
jb <- makeJob(expr=1+var1)
run(jb)
}

