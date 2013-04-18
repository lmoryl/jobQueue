\name{getID}
\alias{getID}
\title{
Get id of JobQueue
}
\description{
The getID function retrieves a JobQueue's id, which uniquely identifies it
to the Redis server.
}
\usage{getID(jq)}
\arguments{
  \item{jq}{A JobQueue object}
}
\value{
The JobQueue's id, a character.
}
\author{
Luke Moryl <lsmoryl@pivotaltargeting.com>
Peter Foley <pwfoley@pivotaltargeting.com>
}
\note{
JobQueue functions require network access to a Redis server (not
included with the doRedis package).
}

