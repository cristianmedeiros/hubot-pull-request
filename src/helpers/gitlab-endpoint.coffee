path    = require 'path'
request = require 'request'
_       = require 'lodash'
async   = require 'async'

AbstractEndpoint = require path.resolve __dirname, 'abstract-endpoint'
getConfig        = require path.resolve __dirname, 'get-config'
Project          = require path.resolve __dirname, '..', 'models', 'project'
MergeRequest     = require path.resolve __dirname, '..', 'models', 'merge-request'
User             = require path.resolve __dirname, '..', 'models', 'user'
Group            = require path.resolve __dirname, '..', 'models', 'group'

module.exports = _.extend {}, AbstractEndpoint,
  name: 'gitlab'

  _readCollaborators: (project, callback) ->
    async.waterfall [
      (asyncCallback) =>
        @_readGroup project.ownerId, (err, group) ->
          return asyncCallback(err, null) if err
          asyncCallback null, group

      (group, asyncCallback) =>
        @_readGroupMembers group, (err, members) ->
          return asyncCallback(err, null) if err
          asyncCallback null, members

      (members, asyncCallback) =>
        @_readProjectMembers project, (err, projectMembers) ->
          return asyncCallback(err, null) if err
          members = members.concat projectMembers
          members = _.uniq members, (user) -> user.id
          asyncCallback null, members
    ], callback

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
  _generateRequestOptions: (remotePath, otherOptions={}) ->
    config  = getConfig().gitlab

    unless config
      throw new Error("There is no configuration for gitlab ...")

    options =
      url: "#{config.host}#{remotePath}",
      headers:
        'PRIVATE-TOKEN': config.api.token

    if config.basic
      options.auth =
        user: config.basic.auth.username,
        pass: config.basic.auth.password

    _.extend(options, otherOptions)

  #
  # callApi - Calls the API and returns its data as a properly transformed object.
  #
  # Parameters:
  # - path: A path on the remote server.
  # - callback: A function that gets called, once the server has responded.
  #
  _callApi: (path, callback, options={}) ->
    request @_generateRequestOptions(path, options), (err, response, body) ->
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
  _readProjects: (callback) ->
    @_callApi '/api/v3/projects', (err, projects) ->
      projects &&= projects.map (project) ->
        new Project(
          id:        project.id
          name:      project.path_with_namespace
          ownerId:   project.namespace.id
          ownerType: null
        )
      callback err, projects

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

    @_callApi "/api/v3/projects/#{project.id}/merge_requests?page=#{page}", (err, requests) ->
      requests &&= requests.map (request) ->
        new MergeRequest(request, project)
      callback err, requests

  #
  # readMergeRequest - Returns a specific merge request.
  #
  # Parameters:
  # - project: An instance of Project
  # - id: An id of a merge request
  # - callback: A function that gets called, once the result is in place.
  #
  _readMergeRequest: (project, id, callback) ->
    unless project instanceof Project
      throw new Error('The passed argument is no instance of Project.')

    @_callApi "/api/v3/projects/#{project.id}/merge_request/#{id}", (err, request) ->
      if request &&= new MergeRequest(request)
        callback null, request
      else
        err ||= new Error("Unable to find merge request ##{id} for project '#{project.displayName}'.")
        callback err, null

  _readMergeRequestViaPublicId: (project, publicId, callback) ->
    unless project instanceof Project
      throw new Error('The passed argument is no instance of Project.')

    @_readMergeRequestsFor project, (err, mergeRequests) =>
      matchingRequests = mergeRequests.filter (mergeRequest) ->
        parseInt(mergeRequest.publicId, 10) == parseInt(publicId, 10)

      if matchingRequests.length == 0
        err ||= new Error("Unable to find merge request ##{publicId} for project '#{project.displayName}'.")
      else if matchingRequests.length > 1
        err ||= new Error('Too many merge requests found.')

      if err
        callback err, null
      else
        callback null, matchingRequests[0]

  _readGroup: (groupId, callback) ->
    @_callApi "/api/v3/groups/#{groupId}", (err, group) ->
      if group &&= new Group(id: group.id)
        callback null, group
      else
        err ||= new Error('No group found')
        callback err, null

  _readGroupMembers: (group, callback) ->
    unless group instanceof Group
      throw new Error('The passed argument is no instance of Group.')

    @_callApi "/api/v3/groups/#{group.id}/members", (err, members) ->
      if err
        callback err, null
      else
        members &&= members.map (member) -> new User(member)
        callback null, members

  _readProjectMembers: (project, callback) ->
    unless project instanceof Project
      throw new Error('The passed argument is no instance of Project.')

    @_callApi "/api/v3/projects/#{project.id}/members", (err, members) ->
      if err
        callback err, null
      else if members.length == 0
        callback new Error("No members found for project '#{project.displayName}'"), null
      else
        members &&= members.map (member) -> new User(member)
        callback null, members

  _assignMergeRequestTo: (member, project, mergeRequest, callback) ->
    unless member instanceof User
      throw new Error('The passed argument is no instance of User.')

    unless project instanceof Project
      throw new Error('The passed argument is no instance of Project.')

    unless mergeRequest instanceof MergeRequest
      throw new Error('The passed argument is no instance of MergeRequest.')

    url       = "/api/v3/projects/#{project.id}/merge_request/#{mergeRequest.id}?assignee_id=#{member.id}"
    _callback = (err, mergeRequest) ->
      if err
        callback err, null
      else
        mergeRequest &&= new MergeRequest(mergeRequest)
        callback null, mergeRequest

    @_callApi url, _callback, method: 'PUT'
