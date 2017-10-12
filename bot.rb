require 'json'
require 'abstraction'

class Bot
    abstract
    attr_reader :token, :bot, :config_file, :config

    def initialize(api)
        @api = api
        @bot = @api.bot
    end


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
