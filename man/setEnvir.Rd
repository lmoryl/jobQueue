\name{setEnvir}
\alias{setEnvir}
\title{
Set Job's environment.
}
\description{
Set a Job's environment.  To see the contents of this environment, apply
as.list() to the environment.

If appendAll is set to TRUE, any new variable assignments bearing the same
names as old ones will overwrite the old ones.
}
\usage{
setEnvir(job, env, appendAll=FALSE)
}
\arguments{
  \item{job}{A Job object.}
  \item{env}{An environment or list of assignments}
  \item{appendAll}{Should the variable assignments be appended to those already
    in the Job's environment?}
}


