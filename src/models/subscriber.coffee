path    = require 'path'
_       = require 'lodash'
async   = require 'async'
User    = require path.resolve __dirname, '..', 'models', 'user'
helpers = require path.resolve(__dirname, '..', 'helpers')

module.exports = class Subscriber
  constructor: (@robot, data) ->
    @service     = data.service
    @project     = data.project
    @user        = data.user
    @userId      = null
    @endpoint    = if @service == "gitlab" then helpers.gitlabEndpoint else helpers.githubEndpoint
    @subscribers = @robot.brain.data.subscribers

  initBrain: ->
    @subscribers ||= {}
    @subscribers[@service] ||= {}
    @subscribers[@service][@project] ||= []

  subscribed: ->
    !! @subscribers[@service] && !! @subscribers[@service][@project] && _.contains(@subscribers[@service][@project], @user)

  save: (callback) ->
    async.waterfall [
      (asyncCallback) =>
        @endpoint._searchProject @project, (err, project) =>
          return asyncCallback(err, null) if err
          asyncCallback null, project

      (project, asyncCallback) =>
        @endpoint._readCollaborators project, (err, collaborators) =>
          return asyncCallback(err, null) if err
          asyncCallback null, collaborators

      (collaborators, asyncCallback) =>
        userNames = collaborators.map (c) -> c.username

        if ! _.contains(userNames, @user)
          asyncCallback(new Error("User #{@user} is not a valid collaborator for #{@service} project #{@project}!"), null)
        else if @subscribed()
          asyncCallback(new Error("User #{@user} is already subscribed to project #{@project}."), null)
        else
          @initBrain()
          @subscribers[@service][@project].push(@user)
          @robot.brain.emit 'save'
          asyncCallback(null, @user)
    ], callback

  remove: ->
    if @subscribed()
      _.pull(@subscribers[@service][@project], @user)
      @robot.brain.emit 'save'
      true
    else
      "User #{@user} was not subscribed to project #{@project}."

  # Retrieves an array of usernames that subscribed to the given service & project.
  # If currentServiceUser is provided, it removes it from the result.
  @findNamesFor: (robot, service, project, currentServiceUser) ->
    subscribers = robot.brain.data.subscribers
    if !! subscribers[service] && !! subscribers[service][project] && subscribers[service][project].length > 0
      _.pull(subscribers[service][project], currentServiceUser)
    else
      null
