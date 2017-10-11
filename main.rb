
require 'rubygems'
require 'telegram/bot'
require './calendar_bot'
require './doge_bot'

token = JSON.parse("./ressource/config/token.json")[:token]; 

CalendarBot.new(token)

DogeBot.new(token)
