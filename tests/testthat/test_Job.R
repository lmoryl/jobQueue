# Testing of Job class:
#
#  general accessors (getResult, getDependsOn, getKey) work before and after running. 
#  Creation and running of jobs locally
#    with env not specified, given as list and given as env
#      ensuring in each case a job does not run til run() is called
#        and ensuring this works when external packages are and are not specified
#  No dependency checking, we're assuming if people are running jobs locally they don't really need dependon.


# test environment handling

test_that("Local Job class stuff works", {
  glob1 <- 1
  glob2 <- 2
  context("Job initialization")

  expect_that(no_env_job <- Job$new(key='A', expr = {Sys.sleep(1.5); 1}), takes_less_than(1))
  expect_that(loc_env_job <- Job$new(key='B', expr = {Sys.sleep(1.5); n}, envir = list(n=1)), takes_less_than(1))
  expect_that(glob_env_job <- Job$new(key='C', expr= {Sys.sleep(1.5); glob1}), takes_less_than(1))
  expect_that(package_job <- new("Job",
    key='B',
    expr = {f = function() {foreach(i=1:2, .combine=sum) %do% {Sys.sleep(1.5); i}}
      g = memoise(f)
      g()},
    packages=c('foreach', 'memoise')), takes_less_than(1))
  context("Job getters")
  expect_that(length(getDependsOn(no_env_job)), equals(0))
  expect_that(getKey(no_env_job), equals('A'))
  expect_that(length(getPackages(no_env_job)), equals(0))
  expect_that(length(getPackages(package_job)), equals(2))
  expect_that(getEnvir(package_job), equals(getEnvir(package_job)))
#Environment stuff
  context("Job environment initialization")
  expect_that(length(as.list(no_env_job$envir)), equals(0))
  expect_that(length(as.list(loc_env_job$envir)), equals(1))
  expect_that(length(as.list(glob_env_job$envir)), equals(1))
  expect_that(glob_env_job$run(), equals(1))
  expect_that(as.list(loc_env_job$envir)$n, equals(1))
  expect_that(as.list(glob_env_job$envir)$glob1, equals(1))
  expect_that(length(as.list(package_job$envir)), equals(0))

# TESTING EVALUATION OF SIMPLE JOB
  context("Local job evaluation")
  job_res <- loc_env_job$run()
  expect_that(job_res, equals(1))
  package_res <- package_job$run()
  expect_that(package_res, equals(3))

# packages
  context("Specified package loads on local machine")
  
})



