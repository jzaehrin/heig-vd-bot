require './per_chat_bot'
require './calendar'
require './admin'

class CalendarPerChatBot < PerChatBot
    include Adminable
    
    attr_accessor :calendars, :subject, :all

    def initialize(config_path, api)
        super(config_path, "calendar", api)
        @subject = ['INF1', 'ARO1', 'MAD', 'MBT']
        @all = Calendar.new('all', Array.new())
        @calendars = @subject.map{|sub| [ sub , Calendar.new( sub, [@all] ) ] }.to_h
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

        def has_super_admin?
            @per_chat_bot.has_super_admin?(@chat_id.to_s)
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
                else
                    listen_user(message)
                end
            when /\/is_admin (.+)/ # test with chat id
                case $1
                when /^(\d+)/
                    reponse(@per_chat_bot.admin?($1))
                when /^([a-zA-Z0-9]{4,})/ # test with username
                    reponse(@per_chat_bot.username_admin?($1))
                end
            when /\/add_admin ([a-zA-Z0-9]{4,})/    
                password = (0...8).map { o[rand(o.length)] }.join
                @per_chat_bot.add_admin($1,password)
                reponse("#$1 invited with key #{password.to_s}.")
            when /\/remove_invitation ([a-zA-Z0-9]{4,})/
                if @per_chat_bot.remove_invited_admin($1) 
                    reponse("#$1 invitation removed.")
                else
                    reponse("#$1 wasn't on the list!")
                end
            when /\/remove_admin ([a-zA-Z0-9]{4,})/
                if @per_chat_bot.remove_admin($1) 
                    reponse("#$1 is not an admin anymore.")
                else
                    reponse("#$1 wasn't on the admins list!")
                end
            when /\/revoke/
                @per_chat_bot.remove_super_admin()
            else
                listen_admin(message)
            end
        end

        def listen_admin(message)
            case message.text
            when '/add_event' # step one : ask for a subject

                kbId = generate_ikb("Which class subject ?", (@per_chat_bot.subject+["Cancel"]).zip((@per_chat_bot.subject+["Cancel"])).each_slice(4).to_a)['result']['message_id']
                @adding_event = {kbId: kbId.to_s}
            else
                listen_user(message)
            end
        end

        def listen_user(message)
            case message.text
            when /\/init/
                unless has_super_admin?
                    @per_chat_bot.set_super_admin(@chat_id)
                    reponse("Congrats! You're now the super admin of this bot.")
                else
                    reponse("The bot are already init.")
                end
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
            when /\/ls (.*)/
                case $1
                when ''
                    reponseHTML("<a href=\"http://rasp-heig.ddns.net/calendars/all.ics\">all.ics</a> :\n" + @per_chat_bot.all.list)
                when /^ ([A-Z]+\d?)/
                    if @per_chat_bot.calendars.key?($1)
                        reponseHTML("<a href=\"http://rasp-heig.ddns.net/calendars/#$1.ics\">#$1.ics</a> :\n" + @per_chat_bot.calendars[$1].list)
                    else
                        reponse($1 + " doesn't correspond to any calendar in the system.")
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
#---------- STEP 2: catch subject, ask for summary
                when /^([A-Z]+\d?)/                     # step two : 
                    @adding_event[:subject] = $1.to_s  # got subject
                    delete_message(@adding_event.delete(:kbId))

                    # need summary
                    reponse("Add event in #$1.")
                    reponse("Summary:", Telegram::Bot::Types::ForceReply.new(force_reply: true))
                    @adding_event[:wait_for_reply] = true
                when /^change_month (\d+) (\d+)/
                    edit_ikb(@adding_event[:kbId], create_calendar_ikb($1, $2))
#---------- STEP 4: catch date, ask for starttime
                when /(\d{1,2})\.(\d{1,2})\.(\d{4})/
                    #reponse("Add event in #{@adding_event[:subject]} with summary:\n#{@adding_event[:summary]}\nFor the date #$1.#$2.#$3")
                    # clear
                    delete_message(@adding_event.delete(:kbId))
                    @adding_event[:date] = DateTime.new($3.to_i, $2.to_i, $1.to_i)
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
#---------- STEP 3: catch summary, ask for date
                    when 'Summary:' # we get subject & summary
                        # show kb for date
                        @adding_event.delete(:wait_for_reply)
                        kbId = generate_ikb("Which day ?", create_calendar_ikb(10, 2017))['result']['message_id']
                        @adding_event[:kbId] = kbId.to_s
                        @adding_event[:summary] = message.text
#---------- STEP 5: catch starttime, ask for duration
                    when 'Starttime (hh:mm):'
                        starttime = message.text.split(":")
                        @adding_event[:date] += Rational(starttime.first.to_f + starttime.last.to_f / 60, 24)
                        reponse("Time set to #{message.text}.")
                        reponse("Duration in minutes (default 45):", Telegram::Bot::Types::ForceReply.new(force_reply: true))
#---------- STEP 6: catch duration, add event in cal
                    when 'Duration in minutes (default 45):'
                        if message.text == ""
                            duration = 45 
                        else
                            duration = message.text.to_i
                        end
                        @per_chat_bot.calendars[@adding_event[:subject]].add(start: @adding_event[:date], summary: @adding_event[:subject].to_s + ": " + @adding_event[:summary], duration: duration )
                        reponse("Add event in #{@adding_event[:subject]} with summary:\n#{@adding_event[:summary]}\nFor the date #{@adding_event[:date]}, with duration #{duration}")
                        @adding_event = Hash.new
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
