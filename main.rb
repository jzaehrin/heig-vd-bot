require 'rubygems'
require 'telegram/bot'
require 'json'
require './calendar_per_chat_bot'
require './calendar_bot'
require './doge_bot'
require './father_bot'
require 'logger'

id = "infc"
config_path = "./ressources/config/"
father_bot = FatherBot.new(config_path, id)

#doge_bot = DogeBot.new(api)

#calendar_bot = CalendarBot.new(api)

calendar_per_chat_bot = CalendarPerChatBot.new(config_path, father_bot)

father_bot.listen(calendar_per_chat_bot)

