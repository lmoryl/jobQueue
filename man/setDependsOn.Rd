\name{setDependsOn}
\alias{setDependsOn}
\title{
Set Job dependencies
}
\usage{
setDependsOn(job, depends, appendNew=FALSE)
}
\arguments{
  \item{job}{A Job object.}
  \item{depends}{A character vector containing keys of depended-on jobs}
  \item{appendAll}{Should the dependencies be added to the ones the Job already
    has, rather than overwriting them?}
}


