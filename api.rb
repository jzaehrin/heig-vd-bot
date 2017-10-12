require 'json'
require 'abstraction'

class Api
    attr_reader :token, :bot, :config_file, :config

    def initialize(config_file)       
        @config_file = config_file
        load_config()
        @token = @config["token"]; 
    end

    def load_config
        @config = JSON.parse(File.read(@config_file))
    end

    def run
        @bot = Telegram::Bot::Client.run(@token)

    def reponse(message, text)
        @bot.api.send_message(chat_id: message.chat.id, text: text)
    end

    def response_photo(message, photo)
        @bot.api.send_photo(chat_id: message.chat.id, photo: photo)
    end

    def send_broadcast(list, text)
        list.map do |id|
            @bot.api.send_message(chat_id: id, text: text)
        end
    end

    def destroy
        @bot
    end
end
