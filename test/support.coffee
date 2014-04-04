path    = require 'path'
Project = require path.resolve __dirname, '..', 'src', 'models', 'project'

support = module.exports =
  _: require 'lodash'
  _s: require 'underscore.string'
  sinon: require 'sinon'
  expect: require 'expect.js'

  cleanUpEnvironment: ->
    keys = Object.keys process.env

    keys.forEach (key) ->
      if key.indexOf 'HUBOT_PULL_REQUEST' == 0
        delete process.env[key]

  ensureEndpointImplementation: (abstract, endpoint) ->
    describe 'inheritance', ->
      beforeEach ->
        @mock = support.sinon.mock(endpoint)
        @mock.expects('_methodMissing').never()

      afterEach ->
        @mock.verify()

      Object.keys(abstract).forEach (methodName) ->
        unless methodName == '_methodMissing'
          it "implemented #{methodName}", ->
            try
              endpoint[methodName]()
            catch e
              if e.message.match(/_methodMissing/)
                throw e

      it "only reveils the public methods of the abstract endpoint", ->
        publicAbstractMethodNames = Object.keys(abstract)

        Object.keys(endpoint).forEach (methodName) ->
          unless support._.contains publicAbstractMethodNames, methodName
            support.expect(support._s.startsWith(methodName, '_')).to.be.ok()

  toJSON: (obj) ->
    JSON.parse(JSON.stringify(obj))

  fixtures:
    gitlab:
      project: (options) ->
        support._.defaults options || {}, {
          id: 1
          path_with_namespace: 'company/project-1'
          namespace:
            id: 1
        }

      mergeRequest: (options) ->
        result = support._.extend {
          id: 1
          state: 'opened'
          title: 'this merge request makes things better'
        }, options || {}
        result.iid ||= 10 + result.id
        result

    github:
      project: (options) ->
        support._.defaults options || {}, {
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
