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
  @property 'isOpen', get: -> _.contains ['open', 'opened'], @state
  @property 'displayState', get: -> @state
  @property 'title', get: -> @data.title
  @property 'displayAssignee', get: -> @data.assignee.username || @data.assignee.login
  @property 'url', get: -> @data.html_url
  @property 'condensed', get: ->
    assignee = if @data.assignee then @displayAssignee else 'unassigned'
    url      = if @url then " » #{@data.html_url}" else ""

    "#{@publicId} » #{@displayState} » #{assignee} » #{@title}#{url}"
