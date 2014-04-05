path    = require 'path'
support = require path.resolve __dirname, '..', 'support'

module.exports = (github) ->
  beforeEach ->
    support.cleanUpEnvironment()

    this.recoverApi = =>
      if !!this.stub
        this.stub = undefined
        this.apiStubs = undefined
        github.github.get.restore()

    this.stubApi = (err, result) =>
      process.env.HUBOT_PULL_REQUEST_GITHUB_AUTH_USERNAME ||= 'username'
      process.env.HUBOT_PULL_REQUEST_GITHUB_AUTH_PASSWORD ||= 'password'

      this.stub ||= support.sinon.stub github.github, 'get', =>
        args     = [].slice.apply(arguments)
        path     = args[0]
        options  = if args.length > 2 then args[1] else null
        callback = args[args.length - 1]
        stub     = (this.apiStubs || {})[path + JSON.stringify(options)]

        if !!stub && (!stub.filter || JSON.stringify(options) == JSON.stringify(stub.filter))
          setTimeout((=>
            err     = stub.error
            status  = if !!err then 404 else 200
            body    = stub.result
            headers = {}

            callback err, status, body, headers
          ), 10)
        else
          console.log "Unsure what to do with the route '#{path}' <-> #{JSON.stringify(options)}."
          setTimeout((-> callback(err, result)), 10)

    this.stubApiFor = (path, filter, err, result) =>
      args = [].slice.apply(arguments)

      if args.length == 3
        result = err
        err    = filter
        filter = null

      this.stubApi()
      this.apiStubs ||= {}
      this.apiStubs[path + JSON.stringify(filter)] = { error: err, result: result, filter: filter }

  afterEach ->
    this.recoverApi()
