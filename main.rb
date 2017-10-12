require 'thread'
require 'rubygems'
require 'telegram/bot'
require 'json'
require './calendar_bot'
require './api'

api = Api.new("./ressources/config/default.json")
api.run()
calendar_bot = CalendarBot.new(api.bot)
calendar_bot.listen

