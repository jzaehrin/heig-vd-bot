require 'json'
require 'abstraction'

class FatherBot  < Bot
    include Adminable
    attr_reader :token, :bot, :id

    def initialize(config_path, id)       
        @id = id
        run
        super(config_path, "default", self) 
    end

    def run
        Telegram::Bot::Client.run(@token) do |bot|
            @bot = bot
        end
    end

    def listen(*bots)
        begin
        @bot.listen do |message|
            bots.each do |bot|
                bot.listen(message)
            end
        end
        
        rescue SystemExit, Interrupt
            #Destroy bots
            bots.each do |bot|
                bot.destroy
            end
        end
    end
end
