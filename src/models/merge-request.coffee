_ = require 'lodash'

Function::property ||= (prop, desc) ->
  Object.defineProperty @prototype, prop, desc

module.exports = class MergeRequest
  constructor: (data, project) ->
    @data    = data
    @project = project

  toJSON: ->
    _.extend @data, project: @project

  @property 'id', get: -> @data.id
  @property 'publicId', get: -> @data.iid || @data.number
  @property 'state', get: -> @data.state
  @property 'isOpen', get: -> @data.state == 'opened'
  @property 'displayState', get: -> @state
  @property 'title', get: -> @data.title
  @property 'displayAssignee', get: -> @data.assignee.username || @data.assignee.login
  @property 'condensed', get: ->
    assignee = if @data.assignee then @displayAssignee else 'unassigned'
    "#{@publicId} » #{@displayState} » #{assignee} » #{@title}"
