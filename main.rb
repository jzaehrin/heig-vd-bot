require 'thread'
require 'rubygems'
require 'telegram/bot'
require 'json'
require './calendar_bot'
require './doge_bot'

token = JSON.parse(File.read("./ressources/config/default.json"))["token"]; 

calendar_bot = Thread.new {
    CalendarBot.new(token, "./ressources/config/calendar.json")
}

doge_bot = Thread.new {
    DogeBot.new(token)
}

calendar_bot.join()
doge_bot.join()
