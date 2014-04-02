path    = require 'path'
request = require 'request'
_       = require 'lodash'
async   = require 'async'
Github  = require 'github'

AbstractEndpoint = require path.resolve __dirname, 'abstract-endpoint'
getConfigs       = require path.resolve __dirname, 'get-configs'
Project          = require path.resolve __dirname, '..', 'models', 'project'
MergeRequest     = require path.resolve __dirname, '..', 'models', 'merge-request'
User             = require path.resolve __dirname, '..', 'models', 'user'
Group            = require path.resolve __dirname, '..', 'models', 'group'

GithubEndpoint = module.exports = _.extend {}, AbstractEndpoint,
  #
  # generateRequestOptions - Returns the options for the request call.
  #
  # Parameters:
  # - otherOptions: Additional options which gets merged into the result.
  #
  # Result:
  # - Object
  #
  generateRequestOptions: (otherOptions={}) ->
    config  = getConfigs().github

    unless config
      throw new Error("There is no configuration for github ...")

    options =
      version: "3.0.0"

    console.log(config)

    _.extend(options, config.github, otherOptions)

  #
  # callApi - Calls the API and returns its data as a properly transformed object.
  #
  # Parameters:
  # - path: A path on the remote server.
  # - callback: A function that gets called, once the server has responded.
  #
  callApi: (path, callback, options={}) ->
    func = ->
      callback null, {}
    setTimeout(func, 10)

Object.defineProperty GithubEndpoint, 'github', get: ->
  options = @generateRequestOptions
  auth    = options.auth
  result  = new Github(_.omit(optios, 'auth'))

  if auth
    result.authenticate auth

  result
