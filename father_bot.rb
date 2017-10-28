require 'json'
require 'abstraction'

class FatherBot  < Bot
    include Adminable
    attr_reader :id, :api

    def initialize(config_path, id)       
        @id = id
        @api
        super(config_path, "default", self)
        @token = @config["token"]
        run
    end

    def run
        Telegram::Bot::Client.run(@token) do |bot|
            @bot = bot
            @api = bot.api
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
            destroy
        end
    end
end
