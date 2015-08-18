# ExecutableHelper
# =======
#
# **ExecutableHelper** provides helper methods to build the command line call
#
# Copyright &copy; Marcel Würsch, GPL v3.0 licensed.

# Module dependencies
childProcess      = require 'child_process'
nconf             = require 'nconf'
logger            = require '../logging/logger'
ParameterHelper   = require './parameterHelper'
# Expose executableHelper
executableHelper = exports = module.exports = class ExecutableHelper

  # ---
  # **constructor**</br>
  # initialize params and data arrays
  constructor: ->
    this.params = []
    this.data = []

  params: []
  data: []

  # ---
  # **buildCommand**</br>
  # Builds the command line executable command</br>
  # `params:`
  #   *executablePath*  The path to the executable
  #   *inputParameters* The received parameters and its values
  #   *neededParameters*  The list of needed parameters
  #   *programType* The program type
  buildCommand: (executablePath, inputParameters, neededParameters, programType) ->
    # get exectuable type
    execType = getExecutionType programType
    # return the command line call
    return execType + ' ' + executablePath + ' ' + this.data.join(' ') + ' ' + this.params.join(' ')

  # ---
  # **matchParams**</br>
  # Matches the received parameter values to the needed parameters</br>
  # `params`
  #   *inputParameters* The received parameters and its values
  #   *inputHighlighter* The received input highlighter
  #   *neededParameters*  The needed parameteres
  #   *imagePath* path to the input image
  #   *req* incoming request
  matchParams: (inputParameters, inputHighlighter, neededParameters,imagePath, req) ->
    parameterHelper = new ParameterHelper()
    for parameter of neededParameters
      #build parameters
      if checkReservedParameters parameter
        #check if highlighter
        if parameter is 'highlighter'
          this.params.push(parameterHelper.getHighlighterParamValues(neededParameters[parameter], inputHighlighter))
        else
          this.data.push(parameterHelper.getReservedParamValue(parameter, imagePath, req))
      else
        value = parameterHelper.getParamValue(parameter, inputParameters)
        if value?
          this.params.push(value)
    return

  # ---
  # **executeCommand**</br>
  # Executes a command using the [childProcess](https://nodejs.org/api/child_process.html) module
  # Returns the data as received from the stdout.</br>
  # `params`
  #   *command* the command to execute
  executeCommand: (command, statIdentifier, callback) ->
    exec = childProcess.exec
    # (error, stdout, stderr) is a so called "callback" and thus "exec" is an asynchronous function
    # in this case, you must always put the wrapping function in an asynchronous manner too! (see line
    # 23)
    logger.log 'info', 'executing command: ' + command
    child = exec(command, { maxBuffer: 1024 * 48828 }, (error, stdout, stderr) ->
      if stderr.length > 0
        err =
          statusText: stderr
          status: 500
        callback err, null, statIdentifier, false
      else
        #console.log 'task finished. Result: ' + stdout
        callback null, stdout, statIdentifier, false
    )

  # ---
  # **getExecutionType**</br>
  # Returns the command for a given program type (e.g. java -jar for a java program)</br>
  # `params`
  #   *programType* the program type
  getExecutionType = (programType) ->
    switch programType
      when 'java'
        return 'java -jar'
      when 'coffeescript'
        return 'coffee'
      else
        return ''


  # ---
  # **checkReservedParameters**</br>
  # Checks if a parameter is in the list of reserverd words as defined in server.NODE_ENV.json</br>
  # `params`
  #   *parameter* the parameter to check
  checkReservedParameters = (parameter) ->
    reservedParameters = nconf.get('reservedWords')
    return parameter in reservedParameters