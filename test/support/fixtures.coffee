_ = require 'lodash'

fixtures = module.exports =
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
