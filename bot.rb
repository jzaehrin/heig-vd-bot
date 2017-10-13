require 'json'
require 'abstraction'

class Bot
    abstract
    attr_reader :token, :bot, :config_file, :config

    def initialize(api)
        @api = api
        @bot = @api.bot
        @markup_empty = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [])
    end


    def reponse(message, text, reply_markup = nil)
        chat_id = message.respond_to?('chat') ? message.chat.id : message.from.id
        @bot.api.send_message(chat_id: chat_id, text: text, reply_markup: reply_markup)
    end

    def delete_message(message)
        @bot.api.delete_message(chat_id: message.from.id, message_id: message.message_id)
    end

    def edit_markup(chat_id, message_id, reply_markup)
        @bot.api.edit_message_reply_markup(chat_id: chat_id, message_id: message_id, reply_markup: reply_markup)
    end

    def delete_kb(chat_id, message_id)
        @bot.api.edit_message_reply_markup(chat_id: chat_id, message_id: message_id, reply_markup: @markup_empty)
    end

    def response_photo(message, photo)
        @bot.api.send_photo(chat_id: message.chat.id, photo: photo)
    end

    def send_broadcast(list, text)
        list.map do |id|
            @bot.api.send_message(chat_id: id, text: text)
        end
    end

    def generate_ikb(message, text, buttons_infos)
        sendMessage = Telegram::Bot::Types::Message.new(reponse(message, text, @markupEmpty)['result'])
        edit_ikb(sendMessage.chat.id, sendMessage.message_id, buttons_infos)
    end

    def edit_ikb(chat_id, message_id, buttons_infos)
        kb = buttons_infos.collect { |row|  
            row.collect { |button| Telegram::Bot::Types::InlineKeyboardButton.new(text: button.first, callback_data: button.last.to_s + " kbId:" + message_id.to_s)
            }
        }
        markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
        edit_markup(chat_id, message_id, markup)
    end
end
