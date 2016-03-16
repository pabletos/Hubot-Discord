# Description:
#   Display mission info at the user's request
#
# Dependencies:
#   None
#
# Configuration:
#   MONGODB_URL - MongoDB url
#   GENESIS_LINE_END - Configuragble line-return character
#   GENESIS_BLOCK_END - Configuragble string for ending blocks
#   GENESIS_DOUBLE_RET - Configurable string for double-line returns
#
# Commands:
#   hubot alerts - Display alerts
#   hubot invasions - Display invasions
#   hubot darvo - Display daily deals
#   hubot news - Display news
#   hubot baro - Display current Baro status/inventory
#   hubot sortie - Display current sortie missions
#
# Author:
#   nspacestd
#   aliasfalse

util = require('util')

Users = require('./lib/users.js')
ds = require('./lib/deathsnacks.js')
ws = require('./lib/worldstate.js')
wikia = require('./lib/wikia.js')

mongoURL = process.env.MONGODB_URL

module.exports = (robot) ->
  userDB = new Users(mongoURL)

  robot.respond /alerts/, (res) ->
    userDB.getPlatform res.message.room, (err, platform) ->
      if err
        robot.logger.error err
      else
        ds.getAlerts platform, (err, data) ->
          if err
            robot.logger.error err
          else
            message =
              if data.length then (alert.toString() for alert in data).join('\n\n')
              else 'There are no alerts at the moment'
            res.send message

  robot.respond /invasions/, (res) ->
    userDB.getPlatform res.message.room, (err, platform) ->
      if err
        robot.logger.error err
      else
        ds.getInvasions platform, (err, data) ->
          if err
            robot.logger.error err
          else
            message =
              if data.length then (invasion.toString() for invasion in data).join('\n\n')
              else 'There are no invasions at the moment'
            res.send message

  robot.respond /darvo/, (res) ->
    userDB.getPlatform res.message.room, (err, platform) ->
      if err
        robot.logger.error err
      else
        ds.getDeals platform, (err, data) ->
          if err
            robot.logger.error err
          else
            message =
              if data.length then(deal.toString() for deal in data).join('\n\n')
              else 'There is no daily deal at the moment'
            res.send message

  robot.respond /news/, (res) ->
    userDB.getPlatform res.message.room, (err, platform) ->
      if err
        robot.logger.error err
      else
        ds.getNews platform, (err, data) ->
          if err
            robot.logger.error err
          else
            if data.length
              if robot.adapterName is 'telegram'
                # Send with Markdown
                message = (news.toString(true, true) for news in data).join('\n\n')
                robot.emit 'telegram:invoke', 'sendMessage',
                  chat_id: res.message.room
                  text: message
                  parse_mode: 'Markdown'
                  disable_web_page_preview: 1
                , (err, response) ->
                  if err
                    robot.logger.error err

              # No Telegram
              else
                message = (news.toString(true, false) for news in data).join('\n\n')
                res.send message
            # No news
            else
              res.send 'There are no news at the moment'

  robot.respond /baro/, (res) ->
    userDB.getPlatform res.message.room, (err, platform) ->
      if err
        robot.logger.error err
      else
        ds.getBaro platform, (err, data) ->
          if err
            robot.logger.error err
          else
            if data?
              res.send data.toString()
            else
              res.send 'No info about Baro'

  robot.respond /wiki\s*([\w\s-]+)?/, (res) ->
    query = res.match[1]
    if not query
      res.reply 'Please specify a search term'
    else
      wikia.wikiaSearch query, (err, data) ->
        if err
          robot.logger.error err
        else if not data
          res.reply 'Not found'
        else
          res.send util.format('[%s](%s)', data.title, data.url.replace('\\', ''))
  
  robot.respond /sortie/, (res) ->
    userDB.getPlatform res.message.room, (err, platform) ->
      if err
        return robot.logger.error err
      ws.getSortie platform, (err, sortie) ->
        if err
          return robot.logger.error err
        res.send sortie.toString()
