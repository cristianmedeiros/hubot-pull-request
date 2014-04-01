module.exports =
  cleanUpEnvironment: ->
    keys = Object.keys process.env

    keys.forEach (key) ->
      if key.indexOf 'HUBOT_PULL_REQUEST' == 0
        delete process.env[key]

  toJSON: (obj) ->
    JSON.parse(JSON.stringify(obj))
