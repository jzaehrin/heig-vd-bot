
require 'rubygems'
require 'telegram/bot'
require 'calendar_bot.rb'
require 'doge_bot.rb'

token = 'my_token'

CalendarBot.new(token)
DogeBot.new(token)
