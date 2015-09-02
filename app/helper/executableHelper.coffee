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
# Expose executableHelper
executableHelper = exports = module.exports = class ExecutableHelper

  # ---
  # **constructor**</br>
  # initialize params and data arrays
  constructor: ->

  executeRequest: (req, cb) ->
    

  # ---
  # **buildCommand**</br>
  # Builds the command line executable command</br>
  # `params:`
  #   *executablePath*  The path to the executable
  #   *inputParameters* The received parameters and its values
  #   *neededParameters*  The list of needed parameters
  #   *programType* The program type
  buildCommand: (executablePath, programType, data, params) ->
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
        return 'java -Djava.awt.headless=true -jar'
      when 'coffeescript'
        return 'coffee'
      else
        return ''
