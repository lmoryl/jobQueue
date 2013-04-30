\name{getWaiting}
\alias{getWaiting}
\title{
Get keys of Jobs in JobQueue awaiting evaluation.
}
\description{
The getWaiting function returns a vector of Job keys in a JobQueue that have not
been started by a worker.
}
\usage{getWaiting(jq)}
\arguments{
  \item{jq}{A JobQueue object}
}
\value{
A vector of Job keys (characters)
}
\note{
JobQueue functions require network access to a Redis server (not
included with the doRedis package).
}



