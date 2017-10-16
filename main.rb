require 'rubygems'
require 'telegram/bot'
require 'json'
require './calendar_per_chat_bot'
require './calendar_bot'
require './doge_bot'
require './api'

api = Api.new("./ressources/config/default.json")
api.run

#doge_bot = DogeBot.new(api)

#calendar_bot = CalendarBot.new(api)

calendar_per_chat_bot = CalendarPerChatBot.new(api)

api.listen(calendar_per_chat_bot)

