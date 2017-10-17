require 'json'
require 'abstraction'

class Bot
    abstract
    attr_reader :token, :bot, :config_file, :config

    def initialize(config_path, config_name, api)
        @id = api.id
        @api = api.bot.api
        @config_file = config_path + config_name + "." + @id + ".json" 
        @Markup_empty = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [])

        load_config()
    end

    def load_config
        @config = JSON.parse(File.read(@config_file))
    end

    def reponse(chat_id, text, reply_markup = nil)
        @api.send_message(chat_id: chat_id, text: text, reply_markup: reply_markup)
    end

    def delete_message(chat_id)
        @api.delete_message(chat_id: chat_id, message_id: message.message_id)
    end

    def edit_markup(chat_id, message_id, reply_markup)
        @api.edit_message_reply_markup(chat_id: chat_id, message_id: message_id, reply_markup: reply_markup)
    end

    def delete_kb(chat_id, message_id)
        @api.edit_message_reply_markup(chat_id: chat_id, message_id: message_id, reply_markup: @Markup_empty)
    end

    def response_photo(chat_id, photo)
        @api.send_photo(chat_id: chat_id, photo: photo)
    end

    def send_broadcast(list, text)
        list.map do |id|
            @api.send_message(chat_id: id, text: text)
        end
    end

    def generate_ikb(chat_id, text, buttons_infos)
        sendMessage = Telegram::Bot::Types::Message.new(reponse(chat_id, text, @markupEmpty)['result'])
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
