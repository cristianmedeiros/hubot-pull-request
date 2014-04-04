_s = require 'underscore.string'

Function::property ||= (prop, desc) ->
  Object.defineProperty @prototype, prop, desc

module.exports = class Project
  constructor: (data) ->
    @id          = data.id
    @displayName = data.name
    @ownerId     = data.ownerId
    @ownerType   = data.ownerType
    
  hasName: (needle) ->
    _s.contains @displayName, needle
