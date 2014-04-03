_       = require 'lodash'
path    = require 'path'
Project = require path.resolve __dirname, '..', 'src', 'models', 'project'

support = module.exports =
  cleanUpEnvironment: ->
    keys = Object.keys process.env

    keys.forEach (key) ->
      if key.indexOf 'HUBOT_PULL_REQUEST' == 0
        delete process.env[key]

  toJSON: (obj) ->
    JSON.parse(JSON.stringify(obj))

  fixtures:
    gitlab:
      project: (options) ->
        _.defaults options || {}, {
          id: 1
          path_with_namespace: 'company/project-1'
          namespace:
            id: 1
        }

      mergeRequest: (options) ->
        result = _.extend {
          id: 1
          state: 'opened'
          title: 'this merge request makes things better'
        }, options || {}
        result.iid ||= 10 + result.id
        result
        
    github:
      project: (options) ->
        _.defaults options || {}, {
          id: 1
          full_name: 'company/project-1'
          owner:
            id: 1
            type: 'User'
        }

  factories:
    project: (options) ->
      data = support.fixtures.gitlab.project(options)
      new Project(
        id: data.id, name: data.path_with_namespace,
        ownerId: data.namespace.id, ownerType: null
      )
