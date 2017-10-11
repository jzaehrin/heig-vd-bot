
require 'rubygems'
require 'telegram/bot'
require 'json'
require './calendar_bot'
require './doge_bot'

token = JSON.parse(File.read("./ressource/config/default.json"))[:token]; 

CalendarBot.new(token, "./ressource/config/calendar.json")
DogeBot.new(token)
