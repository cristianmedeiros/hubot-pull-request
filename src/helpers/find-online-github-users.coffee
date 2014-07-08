  module.exports =
    getActiveUsersWithGithubAccount: (robot, msg, callback) ->
      auth = process.env.HUBOT_HIPCHAT_TOKEN
      allUsers = robot.brain.data.users

      @getActiveRoom msg, auth, (activeRoom) =>
        @getActiveParticipants msg, auth, activeRoom.room_id, (onlineUsers) =>
          @getGithubNames msg, onlineUsers, allUsers, (githubNames) =>
            callback githubNames

    getActiveRoom: (msg, auth, cb) ->
      activeRoomRjid = msg.envelope.user.reply_to

      msg
        .http("https://api.hipchat.com/v1/rooms/list?format=json&auth_token=#{auth}")
        .get() (err, res, body) ->
          rooms       = JSON.parse(body).rooms
          activeRoom  = ""

          for room in rooms
            if room.xmpp_jid == activeRoomRjid
              activeRoom = room
          cb activeRoom

    getActiveParticipants: (msg, auth, activeRoomId, cb) ->
      msg
        .http("https://api.hipchat.com/v1/rooms/show?room_id=#{activeRoomId}&format=json&auth_token=#{auth}")
        .get() (err, res, body) ->
          onlineUsers = JSON.parse(body).room.participants
          cb onlineUsers

    getGithubNames: (msg, onlineUsers, allUsers, cb) ->
      onlineUserIds = (user.user_id for user in onlineUsers)
      githubNames   = []

      for userKey, user of allUsers
        if parseInt(user.id, 10) in onlineUserIds and user.github?
          githubNames.push user.github

      if githubNames.length == 0
        return msg.reply "I couldnt find any users who are online and have a github account stored in my brain."

      cb githubNames
