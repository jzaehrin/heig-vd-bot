require 'json'

class Bot
    attr_reader :token, :bot, :config_file, :config

    def self.new
        raise "Don't do dat !!"
    end

    def initialize(token, config_file)
        @token = token
        @config_file = config_file

        load_config()
    end

    def load_config
        @config = JSON.parse(@config_file)
    end

    def reponse(message, text)
        @bot.api.send_message(chat_id: message.chat.id, text: text)
    end

    def response_photo(message, photo)
        @bot.api.send_photo(chat_id: message.chat.id, photo: photo)
    end

    def send_broadcast(text)
        @config[:broadcast].map do |id|
            @bot.api.send_message(chat_id: id, text: text)
        end
    end
end
