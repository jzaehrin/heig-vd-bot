require './bot'

class CalendarBot < Bot

    def initialize(api)
        super(api)
        @subject = ['INF1', 'ARO1', 'WTF3']
        @days_header = [['Mon','Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].zip([' ']*7)]
    end

    def create_calendar_ikb(month, year)
        month_header = [[['<', "change_month " + (month.to_i-1).to_s + " " + (year).to_s],[month.to_s + "." + year.to_s, ' '], ['>', "change_month " + (month.to_i+1).to_s + " " + (year).to_s]]]
        first_day = Date.new(year.to_i,month.to_i,1).cwday
        days_woffset = [' '] * (first_day-1) + [*1..31] + [' '] * ( (12-first_day) % 7 )
        month_header + @days_header + days_woffset.zip(days_woffset).each_slice(7).to_a
    end

    def listen(message)
# --- has method reply_to_message AND return !nil (is a reply)
        if message.respond_to?('reply_to_message') && !message.reply_to_message.nil?
            answer = message.reply_to_message
            case answer.text
            when /^\/add_event ([A-Z]+\d) SUMMARY/ # we get subject & summary
                # show kb for date
                generate_ikb(message, "Which day ?", create_calendar_ikb(10, 2017))
            end
# --- is a CallbackQuery (care about message.data not .text)
        elsif message.kind_of? Telegram::Bot::Types::CallbackQuery
            case message.data
            when /^([A-Z]+\d) kbId:(\d+)/
                delete_kb(message.from.id, $2)
                # use reponse
                reponse(message, "/add_event #$1 SUMMARY", Telegram::Bot::Types::ForceReply.new(force_reply: true))
            when /^change_month (\d+) (\d+) kbId:(\d+)/
                edit_ikb(message.from.id, $3, create_calendar_ikb($1, $2))
            end
# --- is a classic message (care about message.text)
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
            when /^\/add_event \?/
                reponse(message, "HOWTO : /add_event SUBJECT SUMMARY dd.mm(.aaaa) hh.mm (DURATION_MIN default: 45) (DESCRIPTION)\n")
            when /^\/add_event ([A-Z]+)/
                reponse(message, "Add event in #$1")
            when '/add_event'
                generate_ikb(message, "Which class subject ?", @subject.zip(@subject).each_slice(3).to_a)
            end
        end
    end
end
