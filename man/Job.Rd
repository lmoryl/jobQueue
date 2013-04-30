\name{Job-class}
\docType{class}
\alias{Job-class}
\alias{Job}
\title{
A class containing unevaluated R expressions
}
\description{
A Job's primary purpose is to hold an expression for later evaluation.

While a Job can be created and evaluated on a single machine, its power comes
from its use in combination with a JobQueue to distribute different 
computations across multiple machines.
}
\section{fields}{
  \describe{
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
}
\section{Methods}{
  \describe{
    Each of these has its own help page.
    \item{\code{\link{makeJob}}}{,}
    \item{\code{\link{getKey}}}{,}
    \item{\code{\link{setKey}}}{,}
    \item{\code{\link{getPackages}}}{,}
    \item{\code{\link{setPackages}}}{,}
    \item{\code{\link{getDependsOn}}}{,}
    \item{\code{\link{setDependsOn}}}{,}
    \item{\code{\link{getEnvir}}}{,}
    \item{\code{\link{setEnvir}}}{,}
    \item{\code{\link{sendJobs}}}{,}
    \item{\code{\link{run}}}{,}
  }
}
\author{
  \describe{
    \item{Luke Moryl}{\email{lsmoryl@pivotaltargeting.com}}
    \item{Peter Foley}{\email{pwfoley@pivotaltargeting.com}}
  }
}

