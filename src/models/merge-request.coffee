Function::property ||= (prop, desc) ->
  Object.defineProperty @prototype, prop, desc

module.exports = class MergeRequest
  constructor: (@data) ->
  toJSON: -> @data

  @property 'id', get: -> @data.id
  @property 'state', get: -> @data.state
  @property 'displayState', get: -> @state.toUpperCase()
  @property 'title', get: -> @data.title
