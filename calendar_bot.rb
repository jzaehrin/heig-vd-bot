require './bot'

class CalendarBot < Bot
    @run = lambda { |bot|
        @bot = bot

        bot.listen do |message|
            case message.text
            when '/!set_admin'
                if @config[:admin] then
                    reponse(message, "The admin channel has already set !")
                end
                reponse(message, "This channel has been set to admin")
            when '/!remove_admin'
                reponse(message, "This channel has been removed")
            when '/start_calendar'
                reponse(message, "Hello, #{message.from.first_name}!")
            when '/add_calendar'
                reponse(message, "TODO")
            end
        end
    }

    def initialize(token, config_file = nil)
        super(token, config_file)

        run()
    end

    def run
        Telegram::Bot::Client.run(@token) &@run
    end
end
