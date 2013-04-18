\name{getInProgress}
\alias{getInProgress}
\title{
Get keys of Jobs in JobQueue that are evaluating.
}
\description{
The getInProgress function returns a vector of Job keys in a JobQueue that are
currently being evaluated by a worker.
}
\usage{getInProgress(jq)}
\arguments{
  \item{jq}{A JobQueue object}
}
\value{
A vector of Job keys (characters)
}
\author{
Luke Moryl <lsmoryl@pivotaltargeting.com>
Peter Foley <pwfoley@pivotaltargeting.com>
}
\note{
JobQueue functions require network access to a Redis server (not
included with the doRedis package).
}



