require 'singleton'

class Bot
  include Singleton
    
  attr_reader :bot
  def initialize(bot)
    @bot = bot
  end
end
