require 'json'
require 'abstraction'

class Api
    attr_reader :token, :bot, :config_file, :config

    def initialize(config_file)       
        @config_file = config_file
        load_config()
        @token = @config["token"];
        @bot
    end

    def load_config
        @config = JSON.parse(File.read(@config_file))
    end

    def run
        Telegram::Bot::Client.run(token) do |bot|
            @bot = bot
        end
    end

    def listen(*bots)
        @bot.listen do |message|
            bots.each do |bot|
                bot.listen(message)
            end
        end
    end
end
