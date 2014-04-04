_         = require 'lodash'
path      = require 'path'
async     = require 'async'
Project   = require path.resolve __dirname, '..', 'models', 'project'
getConfig = require path.resolve __dirname, '..', 'helpers', 'get-config'

module.exports =
  #
  # getPaginationBorder - Returns the highest page number for pagination.
  #
  # Can be set via the environment variable HUBOT_PULL_REQUEST_PAGINATION_BORDER.
  # Default: 100
  #
  getPaginationBorder: ->
    config      = getConfig()
    configValue = config.pagination && config.pagination.border
    parseInt(configValue || 100)

  #
  # getPerPage - Returns the number of items per paginated page.
  #
  # Can be set with the environment variable HUBOT_PULL_REQUEST_PAGINATION_PER_PAGE.
  # Default: 100
  #
  getPerPage: ->
    config      = getConfig()
    configValue = config.pagination && config.pagination.per && config.pagination.per.page
    parseInt(configValue || 100)

  #
  # readMergeRequests - Returns merge requests for all projects.
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
    @_readProjects (err, projects) =>
      if err
        callback(err, null)
      else
        async.map(
          projects,
          (project, callback) =>
            @_readMergeRequestsFor project, (err, requests) ->
              callback(err, requests)
          (err, requests) ->
            if err
              callback err, null
            else
              callback null, _.flatten(requests)
        )

  assignMergeRequest: (projectName, mergeRequestId, callback) ->
    @_methodMissing 'assignMergeRequest'

  _readMergeRequestPageFor: (project, page, callback) ->
    @_methodMissing '_readMergeRequestPageFor'

  _readProjects: (callback) ->
    @_methodMissing '_readProjects'

  _methodMissing: (methodName) ->
    throw new Error("The method '#{methodName}' is not implemented!")

  #
  # readMergeRequestsFor - Returns merge requests for a project.
  #
  # Parameters:
  # - project: An instance of Project.
  # - callback: A function that gets called, once the result is in place.
  #
  _readMergeRequestsFor: (project, callback) ->
    unless project instanceof Project
      throw new Error('The passed argument is no instance of Project.')

    mergeRequests = []
    page          = 1

    _callback = (err, requests) =>
      if (err)
        callback(err, null)
      else if requests.length == 0
        callback(null, mergeRequests)
      else if page == @getPaginationBorder()
        callback(new Error('Just iterated to page 100 ... Something is strange!'))
      else
        page += 1
        mergeRequests = mergeRequests.concat requests
        @_readMergeRequestPageFor project, page, _callback

    @_readMergeRequestPageFor project, page, _callback
