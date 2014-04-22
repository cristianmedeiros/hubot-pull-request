path  = require 'path'
_     = require 'lodash'
User  = require path.resolve __dirname, '..', 'models', 'user'

module.exports = class Subscriber
  constructor: (@robot, data) ->
    @service = data.service
    @project = data.project
    @user = data.user
    @subscribers = @robot.brain.data.subscribers

  initBrain: ->
    @subscribers ||= {}
    @subscribers[@service] ||= {}
    @subscribers[@service][@project] ||= []

  subscribed: ->
    _.has(@subscribers, @service) && _.has(@subscribers[@service], @project) && _.indexOf(@subscribers[@service][@project], @user) >= 0

  save: ->
    if @subscribed()
      "User #{@user} is already subscribed to project #{@project}."
    else
      @initBrain()
      @subscribers[@service][@project].push(@user)
      @robot.brain.emit 'save'
      true

  remove: ->
    if @subscribed()
      _.pull(@subscribers[@service][@project], @user)
      @robot.brain.emit 'save'
      true
    else
      "User #{@user} was not subscribed to project #{@project}."

  # Retrieves a random subscribed Github / Gitlab user for the given project.
  @randomUserFor: (service, project, subscribers) ->
    console.log "randomUserFor:"
    console.log service
    console.log project
    console.log subscribers
    if _.has(subscribers, service) && _.has(subscribers[service], project) && subscribers[service][project].length > 0
      new User(id: _.sample(subscribers[service][project]))
    else
      null