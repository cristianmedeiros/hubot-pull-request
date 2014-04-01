path       = require 'path'
getConfigs = require path.resolve(__dirname, 'get-configs')
request    = require 'request'
_          = require 'lodash'
async      = require 'async'

module.exports =
  #
  # generateRequestOptions - Returns the options for the request call.
  #
  # Parameters:
  # - remotePath: The path to the remote server.
  # - otherOptions: Additional options which gets merged into the result.
  #
  # Result:
  # - Object
  #
  generateRequestOptions: (remotePath, otherOptions={}) ->
    config  = getConfigs().gitlab

    unless config
      throw new Error("There is no configuration for gitlab ...")

    options = {
      url: "#{config.host}#{remotePath}",
      headers:
        'PRIVATE-TOKEN': config.apiToken
    }

    if config.basicAuthUsername && config.basicAuthPassword
      options.auth =
        user: config.basicAuthUsername,
        pass: config.basicAuthPassword

    _.extend(options, otherOptions)

  #
  # callApi - Calls the API and returns its data as a properly transformed object.
  #
  # Parameters:
  # - path: A path on the remote server.
  # - callback: A function that gets called, once the server has responded.
  #
  callApi: (path, callback) ->
    request @generateRequestOptions(path), (err, response, body) ->
      if err
        callback(err, null)
      else
        callback(null, JSON.parse(body))

  #
  # readProjects - Return the projects of the gitlab server to the passed callback.
  #
  # Parameters:
  # - callback: A function that gets called, once the result is in place.
  #
  readProjects: (callback) ->
    @callApi '/api/v3/projects', callback

  #
  # readMergeRequestPageFor - Returns a page slice of merge requests for a project.
  #
  # Parameters:
  # - project: A project, read via readProjects.
  # - page: The page that you want to get.
  # - callback: A function that gets called, once the result is in place.
  #
  readMergeRequestPageFor: (project, page, callback) ->
    @callApi "/api/v3/projects/#{project.id}/merge_requests?page=#{page}", callback

  #
  # readMergeRequestFor - Returns merge requests for a project.
  #
  # Parameters:
  # - project: A project, read via readProjects.
  # - callback: A function that gets called, once the result is in place.
  #
  readMergeRequestFor: (project, callback) ->
    mergeRequests = []
    page          = 1
    self          = this

    _callback = (err, requests) ->
      if (err)
        callback(err, null)
      else if requests.length == 0
        callback(null, mergeRequests)
      else if page == 100
        callback(new Error('Just iterated to page 100 ... Something is strange!'))
      else
        page += 1
        mergeRequests = mergeRequests.concat requests
        self.readMergeRequestPageFor project, page, _callback

    @readMergeRequestPageFor project, page, _callback

  #
  # readMergeRequests - Returns merge requests for all project.
  #
  # Parameters:
  # - callback: A function that gets called, once the result is in place.
  #
  # Result:
  # - An array of Objects with:
  #   - project: Project
  #   - requests: An array of merge requests
  #
  readMergeRequests: (callback) ->
    self = this

    @readProjects (err, projects) ->
      async.map(
        projects,
        (project, callback) ->
          self.readMergeRequestFor project, (err, requests) ->
            callback(err, { project: project, requests: requests })
        callback
      )
