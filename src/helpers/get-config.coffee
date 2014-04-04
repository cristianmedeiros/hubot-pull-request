dottie = require 'dottie'
_s     = require 'underscore.string'

module.exports = ->
  environmentVariables = {}

  Object.keys(process.env).forEach (variableName) ->
    if _s.startsWith(variableName, 'HUBOT_PULL_REQUEST_')
      targetVariableName = variableName.replace('HUBOT_PULL_REQUEST_', '')
      targetVariableName = targetVariableName.toLowerCase()
      environmentVariables[targetVariableName] = process.env[variableName]

  dottie.transform environmentVariables, delimiter: '_'
