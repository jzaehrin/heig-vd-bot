require './bot'

class CalendarBot < Bot

    def initialize(api)
        super(api)
    end

    def listen(message)
        if message.respond_to?('reply_to_message') && !message.reply_to_message.nil? # not a CallBack AND not empty (is a reply)
            answer = message.reply_to_message
            case answer.text
            when 'Which class subject ?'
                reponseFrom(message, "Add event in " + message.text)
            end
        elsif message.kind_of? Telegram::Bot::Types::CallbackQuery
            case message.data
            when /INF1 (\d+)/
                deleteKb(message.from.id, $1)
                reponseFrom(message, "INF1 pour la vie #$1")
            when /ARO1 (\d+)/
                deleteKb(message.from.id, $1)
                reponseFrom(message, "ARO1 ok")
            when /WTF3 (\d+)/
                deleteKb(message.from.id, $1)
                reponseFrom(message, "Non...")
            end
        elsif message.respond_to?('text')
            case message.text
            when '/!set_admin'
                if @config["admin"] then
                    reponse(message, "The admin channel has already set !")
                end
                reponse(message, "This channel has been set to admin")
            when '/!remove_admin'
                reponse(message, "This channel has been removed")
            when '/start_calendar'
                reponse(message, "Hello, #{message.from.first_name}!")
            when '/add_calendar'
                reponse(message, "TODO")
            when /^\/add_event ([A-Z]+)/
                reponse(message, "Add event in #$1")
            when '/add_event' # a way using force_reply, and  
                reponse(message, "Which class subject ?", Telegram::Bot::Types::ForceReply.new(force_reply: true))
            when '/add_even'
                markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [])
                sendMessage = Telegram::Bot::Types::Message.new(reponse(message, "Which class subject ?", markup)['result'])
                kb = [
                  Telegram::Bot::Types::InlineKeyboardButton.new(text: 'INF1', callback_data: "INF1 " + sendMessage.message_id.to_s),
                  Telegram::Bot::Types::InlineKeyboardButton.new(text: 'ARO1', callback_data: "ARO1 " + sendMessage.message_id.to_s),
                  Telegram::Bot::Types::InlineKeyboardButton.new(text: 'WTF3', callback_data: "WTF3 " + sendMessage.message_id.to_s)
                ]
                markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
                editKb(sendMessage, markup)
            end
        end
    end
end
