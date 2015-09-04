# ExecutableHelper
# =======
#
# **ExecutableHelper** provides helper methods to build the command line call
#
# Copyright &copy; Marcel Würsch, GPL v3.0 licensed.

# Module dependencies
childProcess        = require 'child_process'
nconf               = require 'nconf'
fs                  = require 'fs'
async               = require 'async'
ImageHelper         = require '../helper/imageHelper'
IoHelper            = require '../helper/ioHelper'
ParameterHelper     = require '../helper/parameterHelper'
ServicesInfoHelper  = require '../helper/servicesInfoHelper'
Statistics          = require '../statistics/statistics'
logger              = require '../logging/logger'
Process             = require '../processingQueue/process'
ConsoleResultHandler= require '../helper/resultHandlers/consoleResultHandler'
FileResultHandler   = require '../helper/resultHandlers/fileResultHandler'
# Expose executableHelper
executableHelper = exports = module.exports = class ExecutableHelper

  # ---
  # **constructor**</br>
  constructor: ->

  # ---
  # **buildCommand**</br>
  # Builds the command line executable command</br>
  # `params:`
  #   *executablePath*  The path to the executable
  #   *inputParameters* The received parameters and its values
  #   *neededParameters*  The list of needed parameters
  #   *programType* The program type
  buildCommand = (executablePath, programType, data, params) ->
    # get exectuable type
    execType = getExecutionType programType
    # return the command line call
    return execType + ' ' + executablePath + ' ' + data.join(' ') + ' ' + params.join(' ')

  # ---
  # **executeCommand**</br>
  # Executes a command using the [childProcess](https://nodejs.org/api/child_process.html) module
  # Returns the data as received from the stdout.</br>
  # `params`
  #   *command* the command to execute
  executeCommand: (command, resultHandler, statIdentifier, callback) ->
    exec = childProcess.exec
    child = exec(command, { maxBuffer: 1024 * 48828 }, (error, stdout, stderr) ->
      resultHandler.handleResult(error, stdout, stderr, statIdentifier, callback)
    )

  # ---
  # **getExecutionType**</br>
  # Returns the command for a given program type (e.g. java -jar for a java program)</br>
  # `params`
  #   *programType* the program type
  getExecutionType = (programType) ->
    switch programType
      when 'java'
        return 'java -Djava.awt.headless=true -jar'
      when 'coffeescript'
        return 'coffee'
      else
        return ''

  executeRequest: (process) ->
      ioHelper = new IoHelper()
      self = @
      async.waterfall [
        (callback) ->
          statIdentifier = Statistics.startRecording(process.req.originalUrl)
          #fill executable path with parameter values
          command = buildCommand(process.executablePath, process.programType, process.parameters.data, process.parameters.params)
          self.executeCommand(command, process.resultHandler, statIdentifier, callback)
          return
        (data, statIdentifier, callback) ->
          console.log 'exeucted command in ' + Statistics.endRecording(statIdentifier, process.req.originalUrl) + ' seconds'
          ioHelper.saveResult(process.imageHelper.imgFolder, process.req.originalUrl, process.parameters.params, data, callback)
          return
        #finall callback, handling of the result and returning it
        ], (err, results) ->
          #start next execution

  preprocessing: (req,processingQueue,requestCallback, queueCallback) ->
    serviceInfo = ServicesInfoHelper.getServiceInfo(req.originalUrl)
    imageHelper = new ImageHelper()
    ioHelper = new IoHelper()
    parameterHelper = new ParameterHelper()
    process = new Process()
    process.req = req
    async.waterfall [
      (callback) ->
        if(req.body.image?)
          console.log 'saving image'
          imageHelper.saveImage(req.body.image, callback)
        else if (req.body.url?)
          imageHelper.saveImageUrl(req.body.url, callback)
        process.imageHelper = imageHelper
        return
      #perform parameter matching
      (imagePath, callback) ->
        @imagePath = imagePath
        @neededParameters = serviceInfo.parameters
        @inputParameters = req.body.inputs
        @inputHighlighters = req.body.highlighter
        @programType = serviceInfo.programType
        @parameters = parameterHelper.matchParams(@inputParameters, @inputHighlighters.segments,@neededParameters,@imagePath, req)
        process.parameters = @parameters
        process.programType = serviceInfo.programType
        process.executablePath = serviceInfo.executablePath
        resultHandler = null
        switch serviceInfo.output
          when 'console'
            resultHandler = new ConsoleResultHandler();
          when 'file'
            @parameters.data[@parameters.data.indexOf('##resultFile##')] = @fullFileName
            resultHandler = new FileResultHandler(@fullFileName);
        process.resultHandler = resultHandler
        callback null
        return
      #try to load results from disk
      (callback) ->
        ioHelper.loadResult(imageHelper.imgFolder, req.originalUrl, @parameters.params, true, callback)
        return
      (data, callback) ->
        if(data?)
          callback null, data
        else
          @getUrl = parameterHelper.buildGetUrl(req.originalUrl,imageHelper.md5, @neededParameters, @parameters.params)
          ioHelper.writeTempFile(imageHelper.imgFolder, req.originalUrl, @parameters.params, callback)
      ],(err, results) ->
        if(err?)
          requestCallback err, null
        else
          if(results?)
            requestCallback err,results
          else
            console.log 'preprocessing done'
            processingQueue.addElement(process)
            requestCallback err, {'status':'planned', 'url':@getUrl}
            queueCallback()
