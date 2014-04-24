# Description:
#   Handle a user's subscriptions to Hubot pull request assignments.
#
# Commands:
#   hubot github me <identifier>?                               - Identifies the calling Hubot user with a given Github user name or returns the current state
#   hubot gitlab me <identifier>?                               - Identifies the calling Hubot user with a given Gitlab user name or returns the current state
#   hubot github s(ubscribe) <project-name> <identifier>        - Subscribe a Github user to receive pull requests to a certain project from Hubot.
#   hubot gitlab s(ubscribe) <project-name> <identifier>        - Subscribe a Gitlab user to receive pull requests to a certain project from Hubot.
#   hubot github uns(ubscribe) <project-name> <identifier>      - Unsubscribe a Github user from receiving pull requests to a certain project from Hubot.
#   hubot gitlab uns(ubscribe) <project-name> <identifier>      - Unsubscribe a Gitlab user from receiving pull requests to a certain project from Hubot.
#   hubot github subscribers <project-name>?                    - List all users subscribed to pull requests via Hubot for a certain Github project.
#   hubot gitlab subscribers <project-name>?                    - List all users subscribed to pull requests via Hubot for a certain Gitlab project.
#

path       = require 'path'
_          = require 'lodash'
helpers    = require path.resolve(__dirname, '..', 'helpers')
Subscriber = require path.resolve(__dirname, '..', 'models', 'subscriber')
Util       = require "util"

module.exports = (robot) ->
  identifyRegExp = /(github|gitlab)\s(me)(\s[^\s]+)?/
  subscribeRegExp = /(github|gitlab)\s(s(ubscribe)?)(\s[^\s]+){2}/
  unsubscribeRegExp = /(github|gitlab)\s(uns(ubscribe)?)(\s[^\s]+){2}/
  listRegExp = /(github|gitlab)\s(subscribers)(\s[^\s]+){0,2}/

  # Parse service, project and user from command
  splitCommand = (msg, regExp) ->
    service = null
    project = null
    user = null

    command   = msg.replace(/(^[^\s]+\s)/, "")
    service   = command.match(/[^\s]+/)[0]
    otherArgs = command.replace(/([^\s]+)\s([^\s]+)(\s)?/, "")
    argsMatch = otherArgs.match(/[^\s]+/g)
    if !! argsMatch
      project   = argsMatch[0] if argsMatch.length >= 1
      user      = argsMatch[1] if argsMatch.length >= 2
    
    { service: service, project: project, user: user }

  prettyPrint = (data) ->
    if data instanceof Array
      _.sortBy(data).join(", ")
    else if typeof data == "string"
      "#{data}\n"
    else if typeof data == "object"
      _.map(data, (val, key) -> "#{key}: #{prettyPrint(val)}").join("\n\n")

  # Identify a Hubot user with a Github / Gitlab user
  robot.respond identifyRegExp, (msg) ->
    command   = msg.envelope.message.text.replace(/(^[^\s]+\s)/, "")
    service   = command.match(/[^\s]+/)[0]
    argsMatch = command.replace(/([^\s]+)\s([^\s]+)(\s)?/, "").match(/[^\s]+/g)
    if argsMatch && argsMatch[0]
      user = argsMatch[0]
      msg.message.user[service] = user
    else
      user = msg.message.user[service]

    if !! user
      msg.reply "Hubot knows you on #{service} as #{user}."
    else
      msg.reply "Hubot doesn't know who you are on #{service}. You can tell him, by calling:\nbender #{service} me <identifier>"

  # Subscribe a user to a project
  robot.respond subscribeRegExp, (msg) ->
    params = splitCommand(msg.envelope.message.text, subscribeRegExp)

    msg.reply "Subscribing #{params.service} user #{params.user} to pull requests for #{params.project}..."

    subscriber = new Subscriber(robot, params)
    subscriber.save (err, user) ->
      if err
        msg.send "An error occured:\n#{err}"
      else
        msg.send "Successfully subscribed #{params.service} user #{params.user} to pull requests for #{params.project}."

  # Unsubscribe a user from a project
  robot.respond unsubscribeRegExp, (msg) ->
    params = splitCommand(msg.envelope.message.text, unsubscribeRegExp)

    subscriber = new Subscriber(robot, params)
    result = subscriber.remove()
    if result == true
      msg.send "#{params.service} subscriber #{params.user} removed from project #{params.project}."
    else if typeof result == "string"
      msg.reply "An error occured:\n#{result}"
    else
      msg.reply "An error occured:\nCould not unsubscribe user."

  # List subscribed users
  robot.respond listRegExp, (msg) ->
    params = splitCommand(msg.envelope.message.text, listRegExp)
    subscribers = robot.brain.data.subscribers
    if !! params.service
      if _.has(subscribers, params.service)
        subscribers = subscribers[params.service]
      else
        msg.send "No subscribers found for #{params.service}."
        return
    if !! params.project
      if _.has(subscribers, params.project)
        subscribers = subscribers[params.project]
      else
        msg.send "No subscribers found for #{params.service} project #{params.project}."
        return

    msg.send prettyPrint(subscribers)
    