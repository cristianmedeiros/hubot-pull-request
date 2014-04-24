Function::property ||= (prop, desc) ->
  Object.defineProperty @prototype, prop, desc

module.exports = class User
  constructor: (@data) ->
  @property 'id', get: -> @data.id
  @property 'username', get: -> @data.username || @data.login
