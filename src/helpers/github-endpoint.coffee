path    = require 'path'
request = require 'request'
_       = require 'lodash'
async   = require 'async'
Github  = require 'octonode'

AbstractEndpoint = require path.resolve __dirname, 'abstract-endpoint'
getConfig       = require path.resolve __dirname, 'get-config'
Project          = require path.resolve __dirname, '..', 'models', 'project'
MergeRequest     = require path.resolve __dirname, '..', 'models', 'merge-request'
User             = require path.resolve __dirname, '..', 'models', 'user'
Group            = require path.resolve __dirname, '..', 'models', 'group'

GithubEndpoint = module.exports = _.extend {}, AbstractEndpoint,
  name: 'github'

  #
  # readMergeRequestPageFor - Returns a page slice of merge requests for a project.
  #
  # Parameters:
  # - project: A project, read via readProjects.
  # - page: The page that you want to get.
  # - callback: A function that gets called, once the result is in place.
  #
  _readMergeRequestPageFor: (project, page, callback) ->
    unless project instanceof Project
      throw new Error('The passed argument is no instance of Project.')

    @github.repo(project.displayName).prs { page: page, per_page: @getPerPage() }, (err, requests) ->
      requests &&= requests.map (request) ->
        new MergeRequest request, project
      callback err, requests

  #
  # generateRequestOptions - Returns the options for the request call.
  #
  # Parameters:
  # - otherOptions: Additional options which gets merged into the result.
  #
  # Result:
  # - Object
  #
  _generateRequestOptions: (otherOptions={}) ->
    config  = getConfig().github

    unless config
      throw new Error("There is no configuration for github ...")

    options =
      version: "3.0.0"

    _.extend(options, config, otherOptions)

  #
  # readProjectsForScope - Return the projects of a certain scope. E.g. user or orgs.
  #
  # Parameters:
  # - url: The url for the scope.
  # - callback: A function that gets called, once the result is in place.
  #
  _readProjectsForScope: (url, callback) ->
    page     = 1
    projects = []

    if typeof url == 'function'
      callback = url
      url      = '/user/repos'

    readPage = (page, _callback) =>
      @github.get url, { page: page, per_page: @getPerPage() }, (err, status, projects, headers) ->
        projects &&= projects.map (project) ->
          new Project(
            id:        project.id
            name:      project.full_name
            ownerId:   project.owner.id
            ownerType: project.owner.type
          )
        _callback err, projects

    iterator = (err, projectSlice) ->
      if err
        callback err, null
      else if projectSlice.length == 0
        callback null, projects
      else
        projects = projects.concat projectSlice
        page     = page + 1
        readPage page, iterator

    readPage page, iterator

  _readProjects: (callback) ->
    @_readGroups (err, groups) =>
      if err
        callback err, null
      else
        urls = groups.map (group) -> "/orgs/#{group.name}/repos"
        urls = urls.concat '/user/repos'

        iterator = (url, callback) =>
          @_readProjectsForScope url, callback

        async.map urls, iterator, (err, projects) =>
          if err
            callback err, null
          else
            projects = _.flatten projects
            projects = _.uniq projects, (project) -> project.id
            callback null, projects

  _readGroups: (callback) ->
    @github.me().orgs (err, orgs) ->
      if err
        callback err, null
      else
        orgs = orgs.map (org) ->
          new Group(id: org.id, name: org.login)
        callback null, orgs

Object.defineProperty GithubEndpoint, 'github', get: ->
  @_github ||= Github.client(@_generateRequestOptions().auth)
