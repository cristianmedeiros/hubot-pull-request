_s = require 'underscore.string'

Function::property ||= (prop, desc) ->
  Object.defineProperty @prototype, prop, desc

module.exports = class Project
  @property 'id', get: -> @data.id
  @property 'displayName', get: -> @data.path_with_namespace
  @property 'ownerId', get: -> @data.namespace.id

  constructor: (@data) ->
  toJSON: -> @data
  hasName: (needle) ->
    _s.contains @displayName, needle
