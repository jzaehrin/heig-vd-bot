require 'abstraction'
require './bot'

class PerChatBot < Bot
    abstract

    def initialize(config_path, config_name, father_bot, flag)
        super(config_path, config_name, father_bot, flag)
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

    class Worker
        abstract

        def initialize(chat_id, per_chat_bot)
            @chat_id = chat_id
            @per_chat_bot = per_chat_bot
        end

        def user_usage
            @per_chat_bot.user_usage
        end

        def get_id
            @per_chat_bot.get_id
        end

        def get_config
            @per_chat_bot.get_config
        end

        def get_flag
            @per_chat_bot.get_flag
        end

        def get_name
            @per_chat_bot.get_name
        end

        def get_api
            @per_chat_bot.get_api
        end

        def get_user_cmds
            @per_chat_bot.get_user_cmds
        end

        def listen(message)
            "Override me !"
        end

        def reponse(text, reply_markup = nil)
            @per_chat_bot.reponse(@chat_id, text, reply_markup) 
        end

        def reponseHTML(text, reply_markup = nil)
            @per_chat_bot.reponseHTML(@chat_id, text, reply_markup) 
        end

        def delete_message(message_id)
            @per_chat_bot.delete_message(@chat_id, message_id) 
        end

        def edit_message(message_id, text)
            @per_chat_bot.edit_message(@chat_id, message_id, text) 
        end

        def edit_markup(message_id, reply_markup)
            @per_chat_bot.edit_markup(@chat_id, message_id, reply_markup) 
        end

        def delete_kb(message_id)
            @per_chat_bot.delete_kb(@chat_id, message_id) 
        end

        def response_photo(photo)
            @per_chat_bot.response_photo(@chat_id, photo) 
        end
        def generate_ikb(text, buttons_infos)
            kb = buttons_infos.collect { |row|  
                row.collect { |button| Telegram::Bot::Types::InlineKeyboardButton.new(text: button.first, callback_data: "/#{get_flag} " + button.last)
                }
            }
            markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
            reponseHTML(text, markup) # returning the message sent with the new ikb
        end

        def edit_ikb(message_id, buttons_infos)
            kb = buttons_infos.collect { |row|  
                row.collect { |button| Telegram::Bot::Types::InlineKeyboardButton.new(text: button.first, callback_data: "/#{get_flag} " + button.last)
                }
            }
            markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
            edit_markup(message_id, markup)
        end

        def exec_cmd(method, message, args)
            if respond_to? method
                method(method).call(message, args)
            else
                @per_chat_bot.method(method).call(message, args)
            end
        end
    end
end
