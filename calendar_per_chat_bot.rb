require './per_chat_bot'
require './calendar'
require './admin'

class CalendarPerChatBot < PerChatBot
    include Adminable

    def initialize(config_path, api)
        super(config_path, "calendar", api)
    end

    def new_worker(chat_id)
        @workers[chat_id] = CalendarWorker.new(chat_id,self)
    end

    def create_calendar_ikb(month, year)
        if month.to_i > 12
            month = 1
            year = year.to_i + 1
        elsif month.to_i < 1
            month = 12
            year = year.to_i - 1
        end
        month_header = [[['<', "change_month " + (month.to_i-1).to_s + " " + year.to_s],[month.to_s + "." + year.to_s, ' '], ['>', "change_month " + (month.to_i+1).to_s + " " + year.to_s]]]
        first_day = Date.new(year.to_i,month.to_i,1).cwday
        nb_days = Date.new(year.to_i, month.to_i, -1).day
        days_woffset = [' '] * (first_day-1) + [*1..nb_days] + [' '] * ( (36-first_day-nb_days) % 7 )
        month_header + [['Mon','Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].zip([' ']*7)] + days_woffset.zip(days_woffset.collect{|d| d.to_s+"."+month.to_s+"."+year.to_s}).each_slice(7).to_a + [[["Cancel","Cancel"]]]
    end

    class CalendarWorker < PerChatBot::Worker

        @@subject = ['INF1', 'ARO1', 'WTF3']

        def initialize(chat_id, per_chat_bot)
            super(chat_id, per_chat_bot)
            @adding_event = Hash.new
        end

        def admin?
            @per_chat_bot.admin?(@chat_id.to_s)
        end

        def super_admin?
            @per_chat_bot.super_admin?(@chat_id.to_s)
        end

        def create_calendar_ikb(month, year)
            @per_chat_bot.create_calendar_ikb(month, year)
        end

        def listen(message)
            if @adding_event.empty?
                super(message)
            else
                listen_adding_event(message)
            end
        end

        def listen_text(message)
            if super_admin?
                listen_super_admin(message)
            elsif admin?
                listen_admin(message)
            else
                listen_user(message)
            end
        end

        def listen_super_admin(message)
            case message.text
            when /\/ls (.+)/
                case $1
                when 'admins'
                    text = "Admins list:\nusername\tchat_id\n"
                    @per_chat_bot.list_admins().each{|admin| text+= admin.first + "\t" + admin.last + "\n"}
                    reponse(text)
                when 'invitations'
                    text = "Admins invitations list:\nusername\tchat_id\n" + @per_chat_bot.list_invited_admin().to_s
                    reponse(text)
                end
            when /\/isAdmin (.+)/ # test with chat id
                case $1
                when /^(\d+)/
                    reponse(@per_chat_bot.admin?($1))
                when /^([a-zA-Z0-9]{4,})/ # test with username
                    reponse(@per_chat_bot.username_admin?($1))
                end
            when /\/add_admin ([a-zA-Z0-9]{4,})/
                if admin?  
                    o = [('a'..'z'), ('A'..'Z'), ('0'..'9')].map(&:to_a).flatten
                    password = (0...8).map { o[rand(o.length)] }.join
                    @per_chat_bot.add_admin($1,password)
                    reponse("#$1 invited with key #{password.to_s}.")
                end
            when /\/remove_invitation ([a-zA-Z0-9]{4,})/
                if admin?
                    if @per_chat_bot.remove_invited_admin($1) 
                        reponse("#$1 invitation removed.")
                    else
                        reponse("#$1 wasn't on the list!")
                    end
                end
            when /\/remove_admin ([a-zA-Z0-9]{4,})/
                if admin?
                    if @per_chat_bot.remove_admin($1) 
                        reponse("#$1 is not an admin anymore.")
                    else
                        reponse("#$1 wasn't on the admins list!")
                    end
                end
            else
                listen_admin(message)
            end
        end

        def listen_admin(message)
            case message.text
            when '/add_event' # step one : ask for a subject

                kbId = generate_ikb("Which class subject ?", (@@subject+["Cancel"]).zip((@@subject+["Cancel"])).each_slice(4).to_a)['result']['message_id']
                @adding_event = {kbId: kbId.to_s}
            else
                listen_user(message)
            end
        end

        def listen_user(message)
            case message.text
            when /\/admin ([a-zA-Z0-9]{8})/
                if admin?
                    reponse("You already are an admin for this bot ;) !")
                else
                    if @per_chat_bot.match_admin(@chat_id.to_s,message.from.username.to_s,$1.to_s)
                        reponse("Congrats! You're now a admin of this bot.")
                    else
                        reponse("Sorry, but you were not invited to become an admin of this bot.")
                    end
                end
            end
        end

        def listen_callback(message)
            case message.data
            when 'test'
                reponse("ko")
            end
        end

        def listen_adding_event(message)
            if message.kind_of? Telegram::Bot::Types::CallbackQuery
                case message.data
                when 'Cancel'
                    if @adding_event.key?(:kbId)
                        delete_message(@adding_event[:kbId])
                    end
                    @adding_event = Hash.new
                when /^([A-Z]+\d)/                     # step two : 
                    @adding_event[:subject] = $1.to_s  # got subject
                    delete_message(@adding_event.delete(:kbId))

                    # need summary
                    reponse("Add event in #$1.")
                    reponse("Summary:", Telegram::Bot::Types::ForceReply.new(force_reply: true))
                    @adding_event[:wait_for_reply] = true
                when /^change_month (\d+) (\d+)/
                    edit_ikb(@adding_event[:kbId], create_calendar_ikb($1, $2))
                when /(\d{1,2})\.(\d{1,2})\.(\d{4})/
                    #reponse("Add event in #{@adding_event[:subject]} with summary:\n#{@adding_event[:summary]}\nFor the date #$1.#$2.#$3")
                    # clear
                    delete_message(@adding_event.delete(:kbId))
                    @adding_event[:date] = $1.to_s + "." + $2.to_s + "." + $3.to_s
                    reponse("Date set to #$1.#$2.#$3.")
                    reponse("Starttime (hh:mm):", Telegram::Bot::Types::ForceReply.new(force_reply: true))
                    @adding_event[:wait_for_reply] = true
                end
            elsif message.respond_to?('reply_to_message') && !message.reply_to_message.nil?
                answer = message.reply_to_message
                if message.text === "q"
                    @adding_event = Hash.new
                    reponse("Operation abort.")
                else
                    case answer.text
                    when 'Summary:' # we get subject & summary
                        # show kb for date
                        @adding_event.delete(:wait_for_reply)
                        kbId = generate_ikb("Which day ?", create_calendar_ikb(10, 2017))['result']['message_id']
                        @adding_event[:kbId] = kbId.to_s
                        @adding_event[:summary] = message.text
                    when 'Starttime (hh:mm):'
                        @adding_event.delete(:wait_for_reply)
                        reponse("Add event in #{@adding_event[:subject]} with summary:\n#{@adding_event[:summary]}\nFor the date #{@adding_event[:date]} at #{message.text}.")
                        @adding_event = Hash.new
                        #test.add(start: DateTime.new(2017,10,7,12,0,0), summary: @adding_event[:subject].to_s + " " + @adding_event[:summary], duration: 45)
                    end
                end
            else
                case message.text
                when 'q'
                    if @adding_event.key?(:kbId)
                        delete_message(@adding_event[:kbId])
                    end
                    @adding_event = Hash.new
                    reponse("Operation abort.")
                else
                    if @adding_event[:wait_for_reply]
                        reponse("Please REPLY to the message above or abort current operation with 'q'.")
                    end
                end
            end
        end


    end
end
