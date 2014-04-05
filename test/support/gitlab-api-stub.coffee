path    = require 'path'
support = require path.resolve __dirname, '..', 'support'

module.exports = (gitlab) ->
  beforeEach ->
    support.cleanUpEnvironment()

    @recoverApi = =>
      if !!@stub
        @stub = undefined
        @apiStubs = undefined
        gitlab._callApi.restore()

    @stubApi = (err, result) =>
      process.env.HUBOT_PULL_REQUEST_GITLAB_HOST = 'http://localhost:1234'
      process.env.HUBOT_PULL_REQUEST_GITLAB_API_TOKEN = '123456789'

      @stub ||= support.sinon.stub gitlab, '_callApi', (path, callback) =>
        if (@apiStubs || {})[path]
          setTimeout((=>
            callback(@apiStubs[path].error, @apiStubs[path].result)
          ), 10)
        else
          setTimeout((-> callback(err, result)), 10)

    @stubApiFor = (path, err, result) =>
      @stubApi()
      @apiStubs ||= {}
      @apiStubs[path] = { error: err, result: result }

  afterEach ->
    @recoverApi()
