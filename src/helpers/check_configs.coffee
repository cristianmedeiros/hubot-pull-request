path       = require 'path'
getConfigs = require path.resolve(__dirname, 'get_configs')

module.exports = ->
  if Object.keys(getConfigs()).length == 0
    throw new Error("No hubot configuration in place. Please define the configuration as per the documentation of the hubot-pull-request plugin.")
