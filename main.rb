require 'rubygems'
require 'telegram/bot'
require 'json'
require './calendar_per_chat_bot'
require './calendar_bot'
require './doge_bot'
require './api'
require 'logger'

id = "infc"
config_path = "./ressources/config/"
api = Api.new(config_path, id)
api.run

#doge_bot = DogeBot.new(api)

#calendar_bot = CalendarBot.new(api)

calendar_per_chat_bot = CalendarPerChatBot.new(config_path, api)

api.listen(calendar_per_chat_bot)

