require(jobQueue)
jq = makeJQRedis(id='jq_id')
startLocalJQWorkers(n=2, queue='jq_id')
for(i in 1:6) {assign(paste0('a',i), Job$new(key=paste0('job',i), expr= {Sys.sleep(3); list('a'=3+runif(1), 'b'=3)}))}
sendQueueJobs(jq, list(a1,a2,a3,a4,a5,a6))
jq$getResults()


require(jobQueue)
starttime = Sys.time()
for(i in 1:4) {assign(paste0('b',i), Job$new(key=paste0('job_2_',i), expr={if(difftime(Sys.time(),starttime) < 5) quit(save='no'); 3+runif(1)}))}
sendQueueJobs(jq, list(b1,b2,b3,b4)
jq$getResults()


require(jobQueue)
jq = makeJQRedis(id='jq_id')
startLocalJQWorkers(n=2, queue='jq_id')
n='External success!'
# The first returns 
jb1=Job$new(key='a', expr=n, envir = list(n='Internal success'))
jb2=Job$new(key='b', expr=n)
sendJobs(jq,list(jb1, jb2))
jq$getResults()

