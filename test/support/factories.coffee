path     = require 'path'
fixtures = require path.resolve __dirname, 'fixtures'
Project  = require path.resolve __dirname, '..', '..', 'src', 'models', 'project'

factories = module.exports =
  project: (options) ->
    data = fixtures.gitlab.project(options)
    new Project(
      id:        data.id,
      name:      data.path_with_namespace,
      ownerId:   data.namespace.id,
      ownerType: null
    )
