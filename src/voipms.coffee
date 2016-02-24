{Robot, Adapter, TextMessage} = require("hubot")

HTTP    = require "http"
QS      = require "querystring"

class VoipMS extends Adapter
  constructor: (robot) ->
    @did        = process.env.HUBOT_VOIPMS_DID
    @user       = process.env.HUBOT_VOIPMS_USER
    @pass       = process.env.HUBOT_VOIPMS_PASS
    @path       = process.env.HUBOT_VOIPMS_PATH || "/hubot/voipms"
    @secret     = process.env.HUBOT_VOIPMS_SECRET || ""
    @whitelist  = (process.env.HUBOT_VOIPMS_WHITELIST || "").split(/\s+/)
    @blacklist  = (process.env.HUBOT_VOIPMS_BLACKLIST || "").split(/\s+/)
    @maxlines   = process.env.HUBOT_VOIPMS_MAXLINES || 3
    @leader     = process.env.HUBOT_VOIPMS_LEADER
    @robot      = robot
    super robot

  send: (user, strings...) ->
    message = strings.join "\n"

    # FIXME
    user = user.user
    
    begin = 0
    lines = 0
    loop
      # Send message in chunks of 140 characters strings or less
      size = 140
      if message.length - begin > size
        end = Math.max(message.lastIndexOf("\n", begin + size), message.lastIndexOf(" ", begin + size))
        size = end - begin if end > begin

      part = message.substr(begin, size)
      
      @send_sms part, user.id, (err, data, body) ->
        if err or not body?
          console.log "! Error sending SMS to #{data.dst}:\n#{err}"
        else
          console.log "# SMS to #{data.dst}:\n#{data.message}"

      begin += size
      break unless begin < message.length
      break unless ++lines < @maxlines or @maxlines is 0

  reply: (user, strings...) ->
    @send user, str for str in strings

  respond: (regex, callback) ->
    @hear regex, callback

  run: ->
    self = @

    @robot.router.get @path, (request, response) =>
      query = QS.parse(request.url)

      if query.message? and query.from? and (query.secret || "") is @secret
        console.log "# SMS from #{query.from}:\n#{query.message}"
        @receive_sms(query.message, query.from)

      response.writeHead 200, "Content-Type": "text/plain"
      response.end("ok")

    self.emit "connected"

  receive_sms: (body, from) ->
    return if body.length is 0
    return if @blacklist? and from in @blacklist
    return if @whitelist? and from not in @whitelist
  
    user = @robot.brain.userForId from

    if @leader?
      if body.indexOf(@leader) is 0
        # Answer to hubot when messages begin with @leader
        body = @robot.name + " " + body.substr(@leader.length)
      if @leader is "[ALWAYS]"
        # Always answer to hubot, but avoid repeating hubot's name
        botname = new RegExp("^\s*[@]?#{@robot.name}\\b", "i")
        if not body.match botname
          body = @robot.name + " " + body

    @receive new TextMessage user, body

  send_sms: (message, to, callback) ->
    data =
      api_password: @pass,
      api_username: @user,
      method: "sendSMS",
      did: @did,
      dst: to,
      message: message

    @robot.http("https://voip.ms")
      .path("/api/v1/rest.php")
      .header("Content-Type", "text/plain")
      .query(data)
      .get() (err, res, body) ->
        if err
          return callback(err, data)
        if res.statusCode isnt 200
          return callback(body.message, data)

        json = JSON.parse(body)

        if String(json.status) isnt "success"
          return callback(json.status, data)

        return callback(null, data, json)

exports.VoipMS = VoipMS

exports.use = (robot) ->
  new VoipMS robot

