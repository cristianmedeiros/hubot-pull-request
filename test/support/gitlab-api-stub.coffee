path    = require 'path'
support = require path.resolve __dirname, '..', 'support'

module.exports = (gitlab) ->
  beforeEach ->
    support.cleanUpEnvironment()

    this.recoverApi = =>
      if !!this.stub
        this.stub = undefined
        this.apiStubs = undefined
        gitlab._callApi.restore()

    this.stubApi = (err, result) =>
      this.stub ||= support.sinon.stub gitlab, '_callApi', (path, callback) =>
        if (this.apiStubs || {})[path]
          setTimeout((=>
            callback(this.apiStubs[path].error, this.apiStubs[path].result)
          ), 10)
        else
          setTimeout((-> callback(err, result)), 10)

    this.stubApiFor = (path, err, result) =>
      this.stubApi()
      this.apiStubs ||= {}
      this.apiStubs[path] = { error: err, result: result }

  afterEach ->
    this.recoverApi()
