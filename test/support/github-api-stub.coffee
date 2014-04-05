path    = require 'path'
support = require path.resolve __dirname, '..', 'support'

module.exports = (github) ->
  beforeEach ->
    support.cleanUpEnvironment()

    @recoverApi = =>
      if !!@stub
        @stub = undefined
        @apiStubs = undefined
        github.github.get.restore()

    @stubApi = (err, result) =>
      process.env.HUBOT_PULL_REQUEST_GITHUB_AUTH_USERNAME ||= 'username'
      process.env.HUBOT_PULL_REQUEST_GITHUB_AUTH_PASSWORD ||= 'password'

      @stub ||= support.sinon.stub github.github, 'get', =>
        args     = [].slice.apply(arguments)
        path     = args[0]
        options  = if args.length > 2 then args[1] else null
        callback = args[args.length - 1]
        stub     = (@apiStubs || {})[path + JSON.stringify(options)]

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

    @stubApiFor = (path, filter, err, result) =>
      args = [].slice.apply(arguments)

      if args.length == 3
        result = err
        err    = filter
        filter = null

      @stubApi()
      @apiStubs ||= {}
      @apiStubs[path + JSON.stringify(filter)] = { error: err, result: result, filter: filter }

  afterEach ->
    @recoverApi()
