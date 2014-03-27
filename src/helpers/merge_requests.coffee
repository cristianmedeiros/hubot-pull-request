path       = require 'path'
getConfigs = require path.resolve(__dirname, 'get_configs')
request    = require 'request'

module.exports =
  read: (callback) ->
    config  = getConfigs().gitlab

    unless config
      throw new Error("There is no configuration for gitlab ...")

    options = {
      url: "#{config.host}/api/v3/projects",
      headers:
        'PRIVATE-TOKEN': config.apiToken
    }

    if config.basicAuthUsername && config.basicAuthPassword
      options.auth =
        user: config.basicAuthUsername,
        pass: config.basicAuthPassword

    request options, (error, response, body) ->
      if error
        callback(error, null)
      else
        callback(null, JSON.parse(body))

