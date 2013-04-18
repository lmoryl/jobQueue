\name{setPackages}
\alias{setPackages}
\title{
Set Job's packages.
}
\description{
Set a character vector of packages required by Job.
}
\usage{
setPackages(job, packages, appendNew=FALSE)
}
\arguments{
  \item{job}{A Job object.}
  \item{packages}{A vector of package names}
  \item{appendAll}{Should the packages given be added to those already required
    by the job, instead of replacing them?}
}


