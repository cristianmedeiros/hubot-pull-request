Function::property ||= (prop, desc) ->
  Object.defineProperty @prototype, prop, desc

module.exports = class Group
  constructor: (@data) ->
  toJSON: -> @data
  ownsProject: (project) ->
    @data.projects.filter (project) ->
      project.id == project.id

  @property 'id', get: -> @data.id
