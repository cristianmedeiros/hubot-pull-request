Function::property ||= (prop, desc) ->
  Object.defineProperty @prototype, prop, desc

module.exports = class Group
  constructor: (data) ->
    @id   = data.id
    @name = data.name
