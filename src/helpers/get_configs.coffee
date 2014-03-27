_s = require 'underscore.string'

module.exports = ->
  environmentVariables     = {}
  environmentVariableNames = Object.keys(process.env).filter (variableName) ->
    if _s.startsWith(variableName, 'HUBOT_PULL_REQUEST_')
      targetVariableName = variableName.replace('HUBOT_PULL_REQUEST_', '')
      targetVariableName = targetVariableName.toLowerCase()
      scopeName          = targetVariableName.match(/^[^_]+/)[0]
      targetVariableName = _s.camelize(targetVariableName.replace(scopeName + '_', ''))

      environmentVariables[scopeName] ||= {}
      environmentVariables[scopeName][targetVariableName] = process.env[variableName]

  environmentVariables

