library(testthat)
library(jobQueue)
rserver_path = '/usr/local/opt/redis/bin/redis-server /usr/local/opt/redis/redis.conf'
system(rserver_path, intern=FALSE, wait=FALSE)

test_dir(file.path('testthat'))

system('pkill redis-server')

#      change getResults to once again return a single result as something with a key attached (otherwise how do we know what result it is?)
#      fix up class to make functions more uniform
#      fix up job cleanup, make sure everything that doesn't belong to the queue gets deleted when workers are

