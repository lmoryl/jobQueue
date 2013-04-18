\name{getResults}
\alias{getResults}
\title{
Get results of finished Jobs in a JobQueue
}
\description{
The getResults function returns a list in which the name of each entry is
a finished Job's key and the value is the Job's result.
}
\usage{getResults(jq, keys=NULL, blocking=FALSE, removeFinished = FALSE, restartFaults = TRUE, verbose=FALSE)}
\arguments{
  \item{jq}{A JobQueue object}
  \item{keys}{A vector of keys.  If none are specified, all available results
    are returned.}
  \item{blocking}{Should the current R process block until all specified keys
    are available?}
  \item{removeFinished}{Should results be deleted from the queue once they are
    retrieved?}
  \item{restartFaults}{Should any Jobs that caused a worker fault be restarted?}
  \item{verbose}{Print information about faults}
}
\author{
Luke Moryl <lsmoryl@pivotaltargeting.com>
Peter Foley <pwfoley@pivotaltargeting.com>
}
\note{
JobQueue functions require network access to a Redis server (not
included with the doRedis package).
}



