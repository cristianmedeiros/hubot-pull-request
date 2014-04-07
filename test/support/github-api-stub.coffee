path    = require 'path'
support = require path.resolve __dirname, '..', 'support'

module.exports = (github) ->
  beforeEach ->
    support.cleanUpEnvironment()

    # schema:
    #
    # githubApiStubs:
    #   method:
    #     stub: stub
    #     rules:  [
    #       path: path
    #       payload: {}
    #       error: error
    #       result: result
    #     ]
    @githubApiStubs = {}

    @recoverGithubApi = =>
      Object.keys(@githubApiStubs).forEach (key) ->
        github.github[key].restore()
      @githubApiStubs = {}

    @evaluateGithubApiCall = (method) =>
      args     = [].slice.apply(arguments)
      method   = args[0]
      path     = args[1]
      payload  = if args.length > 3 then args[2] else null
      callback = args[args.length - 1]
      stub     = @githubApiStubs[method].stub
      rules    = @githubApiStubs[method].rules.filter (rule) ->
        rule.path == path &&
        JSON.stringify(rule.payload) == JSON.stringify(payload)

      if rules.length == 0
        console.log "Unsure what to do with the following route: #{method.toUpperCase()} #{path} - #{JSON.stringify(payload)}."
        setTimeout((-> callback(new Error('no match for route'), null)), 10)
      else
        rule = rules[0]

        setTimeout((=>
          status = if !!rule.error then 404 else 200
          callback rule.err, status, rule.result, {}
        ), 10)

    @stubGithubEnvironmentVariables = ->
      process.env.HUBOT_PULL_REQUEST_GITHUB_AUTH_USERNAME ||= 'username'
      process.env.HUBOT_PULL_REQUEST_GITHUB_AUTH_PASSWORD ||= 'password'

    @stubGithubApiFor = (method, path, payload, err, result) =>
      @stubGithubEnvironmentVariables()

      @githubApiStubs[method] ||=
        rules: []
        stub: support.sinon.stub github.github, method, =>
          args = [].slice.apply(arguments)
          @evaluateGithubApiCall.apply this, [method].concat(args)

      @githubApiStubs[method].rules.push(
        path:    path
        payload: payload
        error:   err
        result:  result
      )

  afterEach ->
    @recoverGithubApi()
