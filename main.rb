
require 'rubygems'
require 'telegram/bot'
require './doge_bot'

token = JSON.parse("./ressource/config/token.json")[:token]; 

CalendarBot.new(token, "./ressource/config/calendar.json")
DogeBot.new(token)
