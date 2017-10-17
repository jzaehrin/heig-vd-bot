require 'abstraction'
require './bot'

class PerChatBot < Bot
    abstract

    def initialize(config_path, config_name, api)
    	super(config_path, config_name, api)
        @workers = Hash.new
    end

    def get_worker(chat_id)
        if @workers.empty? || !@workers.has_key?(chat_id)
            new_worker(chat_id)
        end
        @workers[chat_id]
    end

    def new_worker(chat_id)
        raise "override me as following:\n@workers.merge({chat_id => {WORKER_T_HERE}.new(chat_id)})"
    end

    def listen(message)
        chat_id = message.respond_to?('chat') ? message.chat.id : message.from.id
        get_worker(chat_id).listen(message)   
    end

    class Worker < Bot
        abstract

        def initialize(chat_id)
            @chat_id = chat_id
        end

        def listen(message)
            if message.kind_of? Telegram::Bot::Types::CallbackQuery then listen_callback(message)
            elsif message.respond_to?('chat') then listen_text(message) end
        end

        def listen_text(message)
            raise "Override me !"
        end

        def listen_callback(message)
            raise "Override me !"
        end

        def reponse(text, reply_markup=nil)
            super(@chat_id.to_i, text, reply_markup)
        end

        def delete_message(message_id)
            super(@chat_id, message_id)
        end

        def edit_markup(message_id, reply_markup=nil)
            super(@chat_id, message_id, reply_markup)
        end

        def delete_kb(message_id)
            super(@chat_id, message_id)
        end

        def response_photo(photo)
            super(@chat_id, photo)
        end

        def generate_ikb(text, buttons_infos)
            kb = buttons_infos.collect { |row|  
                row.collect { |button| Telegram::Bot::Types::InlineKeyboardButton.new(text: button.first, callback_data: button.last)
                }
            }
            markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
            reponse(text, markup) # returning the message sent with the new ikb
        end

        def edit_ikb(message_id, buttons_infos)
            kb = buttons_infos.collect { |row|  
                row.collect { |button| Telegram::Bot::Types::InlineKeyboardButton.new(text: button.first, callback_data: button.last)
                }
            }
            markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
            edit_markup(message_id, markup)
        end

    end
end
