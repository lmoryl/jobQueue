test_that("Job Queue works", {
  require('jobQueue')
  jq <- JobQueueRedis$new(id='jq')
  envjoblst = sapply(paste0('job',1:4), function(j) {Job$new(key=j, expr=n, envir = list(n=1))})
  depender_job1 = Job$new(key='depender1', expr={jq$getResults('dependee1') + jq$getResults('dependee2') + n}, envir = list(n=1), dependsOn = c('dependee1', 'dependee2'))
  depender_job2 = Job$new(key='depender2', expr={jq$getResults('dependee1') + jq$getResults('dependee2') + n}, envir = list(jq=jq,n=2), dependsOn = c('dependee1', 'dependee2'))
  dj3 = Job$new(key='dj3', expr=2, dependsOn='job1')
  dj4 = Job$new(key='dj4', expr=3, dependsOn='job2')
  dependee_job1 = Job$new(key='dependee1', expr={Sys.sleep(4); 1})
  dependee_job2 = Job$new(key='dependee2', expr={Sys.sleep(8); 10})
  jq$send(depender_job1)

  context("getWaiting works")
  expect_that(length(getWaiting(jq)), equals(1))

  context("Can't send same job twice")
  expect_that(sendJobs(queue=jq, depender_job1), gives_warning())

#  For v2.0?
#  context("Can delete job from Waiting queue")
#  context("... and send it once again")

  startJQWorkers(2, queue='jq')
  Sys.sleep(3) #give the workers time to start
 
  context("Outstanding dependency blocks job evaluation")
  expect_that(length(jq$getWaiting()), equals(1))

  jq$send(dependee_job1, dependee_job2)
  Sys.sleep(2)

  context("inProgress adds in progress jobs")
  expect_that(length(jq$getInProgress()), equals(2))

  Sys.sleep(4)
  context("inProgress removes finished jobs")
  expect_that(length(jq$getInProgress()), equals(1))

  context("Job evaluates remotely and getResults works")
  res<-jq$getResults(removeFinished=FALSE)
  expect_that(length(res), equals(1))

  context("Job without environment evaluates correctly")
  expect_that(res[[1]], equals(1))
  
  context("getResults keeps finished jobs in place when told to do so")
  expect_that(length(jq$getResults(removeFinished=TRUE)), equals(1))
  context("and deletes them when told to do so.")
  expect_that(length(jq$getResults(removeFinished=TRUE)), equals(0))

  jq$send(depender_job2) #To check that a job sent after some dependencies are complete will still work fine

  context("Depending jobs don't run til all dependencies are finished")
  expect_that(length(jq$getWaiting()), equals(2))
  Sys.sleep(7) #Let other dependee finish
  context("Dependees now evaluate properly")
  res1 = jq$getResults()
  expect_that(length(res1), equals(2))
  
  context("Job evaluation with environment works")
  jq$send(envjoblst)
  Sys.sleep(4)
  res <- jq$getResults()
  expect_that(length(res), equals(6))
  expect_that(res$job1, equals(1))

  context("Queue responds to worker failure by restarting the job")
  t1 <- Sys.time()
  time_job <- Job$new(key='time_job', expr={if(Sys.time() - t1 < 5) {Sys.sleep(5); quit(save='no')} else 0})
  jq$send(time_job)
  Sys.sleep(10)
  invisible(jq$getResults())  # Currently fault tolerance checks are only done when another job completes or getResults() is called.  Should change to be managed in alive.c or a forked process.
  Sys.sleep(1)
  jq$getResults()
  expect_that(jq$getResults()$time_job, equals(0))

  deljoblst = sapply(paste0('del',1:4), function(j) {Job$new(key=j, expr=quit(save='no'))})
  jq$send(deljoblst)
  Sys.sleep(0.5)
  redisDelete(redisKeys()); redisClose()
})

