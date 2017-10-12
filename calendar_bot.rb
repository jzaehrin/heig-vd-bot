require './bot'

class CalendarBot < Bot

    def initialize(api)
        super(api)
    end

    def listen(message)
        if message.respond_to?('text')
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
            when '/add_event'
                reponse(message, "Where ?", Telegram::Bot::Types::ForceReply.new())
            end
        end
    end
end
