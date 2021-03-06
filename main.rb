require 'rubygems'
require 'telegram/bot'
require 'json'
require './calendar_per_chat_bot'
require './father_bot'
require 'logger'

id = "infc"
logger = Logger.new('./ressources/log/main.txt', 'daily')
config_path = "./ressources/config/"
father_bot = FatherBot.new(config_path, id, logger)

#calendar_bot = CalendarBot.new(api)

calendar_per_chat_bot = CalendarPerChatBot.new(config_path, father_bot)

father_bot.add_bot(calendar_per_chat_bot)

father_bot.listen()
