require 'rubygems'
require 'telegram/bot'
require 'json'
require './calendar_bot'
require './doge_bot'
require './api'

api = Api.new("./ressources/config/default.json")
api.run

doge_bot = DogeBot.new(api)

calendar_bot = CalendarBot.new(api)

api.listen(calendar_bot)

