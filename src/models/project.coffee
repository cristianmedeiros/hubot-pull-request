Function::property ||= (prop, desc) ->
  Object.defineProperty @prototype, prop, desc

module.exports = class Project
  constructor: (@data) ->
  toJSON: -> @data

  @property 'id', get: -> @data.id
  @property 'displayName', get: -> @data.path_with_namespace
