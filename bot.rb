require 'json'
require 'abstraction'

class Bot
    abstract
    attr_reader :config_file, :flag

    def initialize(config_path, name, father_bot, flag)
        @id = father_bot.id
        @api = father_bot.api
        @flag = flag
        @name = name
        @config_file = config_path + @name + "." + @id + ".json" 
        @Markup_empty = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [])
        @user_cmds = {"def_cmd" => :def_cmd, "help" => :help}
        
        load_config()
    end

    def load_config
        @config = JSON.parse(File.read(@config_file))
    end

    def update_config
        File.open(@config_file, "w") do |f|
            f.write(@config.to_json)
        end
    end
    
    def name
        "Calendar bot"
    end
    
    def get_id
        @id
    end

    def get_config
        @config
    end

    def get_flag
        @flag
    end

    def get_name
        @name
    end

    def get_api
        @api
    end

    def get_user_cmds
        @user_cmds
    end
 
    def user_usage
        get_user_cmds.map{ |k, v| 
            "<code>#{k}</code>\n#{get_method_help(v)}" if k!= "def_cmd"
        }.drop(1).join("\n")
    end
    
    def get_method_help(methode_name)
        "Override me !"
        #eval "@@" + methode_name.to_s + "_usage"
    end

    
    def usage_prefix
        "My prefix is '#{get_flag}'"
    end

    def short_usage
        "- #{usage_prefix} and you can show my help with '/#{get_flag} help'"
    end

    def usage(chat_id)
        usage = user_usage

        <<~HEREDOC
            Help for <b>#{name}</b> :
            #{usage_prefix}
            #{usage}
        HEREDOC

    end

    def reponse(chat_id, text, reply_markup = nil)
        get_api.send_message(chat_id: chat_id, text: text, reply_markup: reply_markup)
    end

    def reponseHTML(chat_id, text, reply_markup = nil)
        get_api.send_message(chat_id: chat_id, text: text, reply_markup: reply_markup, parse_mode: "HTML")
    end

    def delete_message(chat_id, message_id)
        get_api.delete_message(chat_id: chat_id.to_s, message_id: message_id.to_s)
    end

    def edit_message(chat_id, message_id, text)
        get_api.edit_message_text(chat_id: chat_id.to_s, message_id: message_id.to_s, text: text.to_s)
    end

    def edit_markup(chat_id, message_id, reply_markup)
        get_api.edit_message_reply_markup(chat_id: chat_id, message_id: message_id, reply_markup: reply_markup)
    end

    def delete_kb(chat_id, message_id)
        get_api.edit_message_reply_markup(chat_id: chat_id, message_id: message_id, reply_markup: @Markup_empty)
    end

    def response_photo(chat_id, photo)
        get_api.send_photo(chat_id: chat_id, photo: photo)
    end

    def send_broadcast(list, text, reply_markup = nil)
        list.each do |chat_id|
            get_api.send_message(chat_id: chat_id.to_s, text: text.to_s, reply_markup: reply_markup)
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

    def get_text(message)
        if message.kind_of? Telegram::Bot::Types::CallbackQuery
            message.data
        else 
            message.text
        end
    end

    def destroy
        update_config
    end

    #============Command to Functions
    @@help_usage = "- show this help message"
    def help(message, args)
        chat_id = message.chat.id
        reponseHTML(chat_id, usage(chat_id)) 
    end
    
    def def_cmd(message, args)
        # only cmd without _usage
        reponseHTML(message.chat.id, short_usage) 
    end
end
