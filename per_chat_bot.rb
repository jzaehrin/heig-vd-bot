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

    class Worker < Bot
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
    end
end
