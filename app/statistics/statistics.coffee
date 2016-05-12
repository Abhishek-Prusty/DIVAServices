# Statistics
# ======
#
# **Statistics** makes use of [process -> hrtime](http://nodejs.org/docs/v0.8.0/api/all.html#all_process_hrtime)
# to record processing times.
# Keeps also track of which methods are currently executed
#
# Copyright &copy; Marcel Würsch, GPL v3.0 Licensed.

# Module dependencies
_           = require 'lodash'
nconf       = require 'nconf'
fs          = require 'fs'
logger      = require '../logging/logger'


statistics = exports = module.exports = class Statistics

  @currentExecutions = []
  @currentStatistics = {}
  @startTime = 0

  constructor ->
    @startTime = 0

  @getNumberOfCurrentExecutions: () ->
    return @currentExecutions.length

  @isRunning :(reqPath) ->
    executionInfo = @currentExecutions.filter (x) -> x.path == reqPath
    return executionInfo.length > 0

  @getProcess: (rand) ->
    execution = @currentExecutions.filter (x) -> x.rand == rand
    return execution[0].process

  @startRecording: (reqPath, job) ->
    @startTime = process.hrtime()
    rand = Math.random().toString(36).substring(2)
    @currentExecutions.push({
      rand : rand
      startTime: @startTime
      path: reqPath
      process: job
    })
    return rand

  @endRecording: (rand, reqPath) ->
    executionInfo = @currentExecutions.filter (x) -> x.rand == rand
    @endTime = process.hrtime(executionInfo[0].startTime)
    delete @currentExecutions[rand]
    if(_.find(@currentStatistics,{'reqPath':reqPath})?)
      stats = _.find(@currentStatistics,{'reqPath':reqPath})
      stats.runtime = (stats.runtime + @endTime[0]) / 2
      stats.executions = stats.executions+1
    else
      @currentStatistics.push({
        reqPath: reqPath
        runtime: @endTime[0]
        executions: 1
        }
      )
    #remove the call from current executions
    @currentExecutions = @currentExecutions.filter (x) -> x.rand != rand
    fs.writeFileSync nconf.get('paths:statisticsFile'), JSON.stringify(@currentStatistics)
    return @endTime[0]

  @getMeanExecutionTime: (reqPath) ->
    if(_.find(@currentStatistics,{'reqPath':reqPath})?)
      return _.find(@currentStatistics,{'reqPath':reqPath}).runtime
    else
      return -1

  @loadStatistics: () ->
    if(Object.keys(@currentStatistics).length is 0)
      try
        @currentStatistics = JSON.parse(fs.readFileSync(nconf.get('paths:statisticsFile'),'utf-8'))
      catch error
        #Should only happen at first startup
        logger.log 'error', 'No statistics file found'

  @saveStatistics: () ->
    fs.writeFileSync nconf.get('paths:statisticsFile'), JSON.stringify(@currentStatistics)
