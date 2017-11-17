require './per_chat_bot'
require './calendar'
require './admin'

class CalendarPerChatBot < PerChatBot
    include Adminable
    
    attr_accessor :calendars, :subject, :all, :channel

    def initialize(config_path, father_bot)
        super(config_path, "calendar", father_bot, "c")
        @subject = ['INF1', 'ARO1', 'MAD', 'MBT']
        @all = Calendar.new('all', Array.new())
        @calendars = @subject.map{|sub| [ sub , Calendar.new( sub, [@all] ) ] }.to_h
        @channel = @config["channel"]
    end

    def new_worker(chat_id)
        @workers[chat_id] = CalendarWorker.new(chat_id,self)
    end

    def name
        "Calendar bot"
    end
    
    def usage_prefix
        "My prefix is '#{@flag}'"
    end

    def short_usage
        "- #{usage_prefix} and you can show my help with '/#{@flag} help'"
    end

    def super_admin_usage
        <<~HEREDOC
            <b>Super admin usage:</b>
            <code> add_admin USER</code>
            - return a key to promote "USER" (without @) as admin
            <code> is_admin USER</code>
            - tell if "USER" (without @) is admin or not 
            <code> ls PARAM</code>
            - "PARAM" can take "admins" to lists all admins
            - or "invitations" to lists all invitations
            - see <code>ls</code> form <i>user usage</i>
            <code> remove_admin USER</code>
            - remove "USER" (without @) from admin list
            <code> remove_invitation USER</code>
            - remove the invitation for "USER" (without @) 
            <code> revoke</code>
            - revoke the current super admin
            - see <code>init</code> from <i>user usage</i>
        HEREDOC
    end

    def admin_usage
        <<~HEREDOC
            <b>Admin usage:</b>
            <code> add_event</code>
            - start the adding event procedure
        HEREDOC
    end

    def user_usage
        <<~HEREDOC
            <b>User usage:</b>
            <code> admin KEY</code> 
            - promote yourself as admin of this bot
            <code> chan</code>
            - show the broadcast channel id
            <code> help</code>
            - show this help message
            <code> id</code>
            - show this chat unique ID
            <code> init</code>
            - you will become super admin if there is none
            <code> ls CAL</code>
            - lists the content of the calendar "CAL"
            - lists the main calendar if "CAL" isn't specified
        HEREDOC
    end

    def usage(chat_id)
        usage = user_usage
        usage += admin_usage if admin? chat_id.to_s
        usage += super_admin_usage if super_admin? chat_id.to_s

        <<~HEREDOC
            Help for <b>#{name}</b> :
            #{usage_prefix}
            #{usage}
        HEREDOC

    end

    def add_subscribe(chat_id, calendar)
        @config["subscribe"][chat_id.to_s] = calendar
    end

    def create_calendar_ikb(month, year)
        if month.to_i > 12
            month = 1
            year = year.to_i + 1
        elsif month.to_i < 1
            month = 12
            year = year.to_i - 1
        end

        month_header = [[['<', "/#{@flag} change_month " + (month.to_i-1).to_s + " " + year.to_s],[month.to_s + "." + year.to_s, ' '], ['>', "/#{@flag}  change_month " + (month.to_i+1).to_s + " " + year.to_s]]]
        first_day = Date.new(year.to_i,month.to_i,1).cwday
        nb_days = Date.new(year.to_i, month.to_i, -1).day
        days_woffset = [' '] * (first_day-1) + [*1..nb_days] + [' '] * ( (36-first_day-nb_days) % 7 )
        month_header + [['Mon','Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].zip([' ']*7)] + days_woffset.zip(days_woffset.collect{|d| d.to_s+"."+month.to_s+"."+year.to_s}).each_slice(7).to_a + [[["Cancel","/#{@flag} Cancel"]]]
    end

    class CalendarWorker < PerChatBot::Worker
        def initialize(chat_id, per_chat_bot)
            super(chat_id, per_chat_bot)
            @adding_event = Hash.new
            @subscribe_event = Hash.new
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
            if !@adding_event.empty?
                listen_adding_event(message)
            elsif !@subscribe_event.empty?
                listen_subscribe_event(message)
            else
                super(message)
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
            when /ls (.+)/
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
            when /is_admin (.+)/ # test with chat id
                case $1
                when /^(\d+)/
                    reponse(@per_chat_bot.admin?($1))
                when /^([a-zA-Z0-9]{4,})/ # test with username
                    reponse(@per_chat_bot.username_admin?($1))
                end
            when /add_admin ([a-zA-Z0-9]{4,})/    
                password = (0...8).map { o[rand(o.length)] }.join
                @per_chat_bot.add_admin($1,password)
                reponse("#$1 invited with key #{password.to_s}.")
            when /remove_invitation ([a-zA-Z0-9]{4,})/
                if @per_chat_bot.remove_invited_admin($1) 
                    reponse("#$1 invitation removed.")
                else
                    reponse("#$1 wasn't on the list!")
                end
            when /remove_admin ([a-zA-Z0-9]{4,})/
                if @per_chat_bot.remove_admin($1) 
                    reponse("#$1 is not an admin anymore.")
                else
                    reponse("#$1 wasn't on the admins list!")
                end
            when 'revoke'
                @per_chat_bot.remove_super_admin()
            else
                listen_admin(message)
            end
        end

        def listen_admin(message)
            case message.text
#---------- STEP 1: ask for a subject
            when /add_event/
                kbId = generate_ikb("Which class subject ?", (@per_chat_bot.subject+["Cancel"]).zip((@per_chat_bot.subject+["Cancel"])).each_slice(4).to_a)['result']['message_id']
                @adding_event = {kbId: kbId.to_s}
            else
                listen_user(message)
            end
        end

        def listen_user(message)
            case message.text
            when '/' + @per_chat_bot.flag
                reponse(@per_chat_bot.short_usage)
            when /help/
                reponseHTML(@per_chat_bot.usage(@chat_id))
            when /init/
                unless has_super_admin?
                    @per_chat_bot.set_super_admin(@chat_id)
                    reponse("Congrats! You're now the super admin of this bot.")
                else
                    reponse("This bot has already been initialize.")
                end
            when /admin ([a-zA-Z0-9]{8})/
                if admin?
                    reponse("You already are an admin for this bot ;) !")
                else
                    if @per_chat_bot.match_admin(@chat_id.to_s,message.from.username.to_s,$1.to_s)
                        reponse("Congrats! You're now a admin of this bot.")
                    else
                        reponse("Sorry, but you were not invited to become an admin of this bot.")
                    end
                end
            when /chan/
                reponse(@per_chat_bot.channel)
                #callback = @per_chat_bot.reponseHTML("", "test")
                #reponse(callback['result']['chat']['id'])
            when /id/
                reponse("id : " + message.chat.id.to_s)
            when /ls(.*)?/
                case $1
                when /^ (.*)/
                    if @per_chat_bot.calendars.key?($1)
                        reponseHTML("<a href=\"http://rasp-heig.ddns.net/calendars/#$1.ics\">#$1.ics</a> :\n" + @per_chat_bot.calendars[$1].list)
                    else
                        reponse($1 + " doesn't correspond to any calendar in the system.")
                    end
                else
                    reponseHTML("<a href=\"http://rasp-heig.ddns.net/calendars/all.ics\">all.ics</a> :\n" + @per_chat_bot.all.list)
                end
            when /subscribe/
                kb_content = (@per_chat_bot.subject+["Done"]).zip((@per_chat_bot.subject+["Done"])).each_slice(4).to_a
                kbId = generate_ikb("Which subject do you want to subscribe to ?", kb_content)['result']['message_id']
                @subscribe_event = {kbId: kbId.to_s, kb_content: kb_content}
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
                when /Cancel/
                    if @adding_event.key?(:kbId)
                        delete_message(@adding_event[:kbId])
                    end
                    @adding_event = Hash.new
#---------- STEP 2: catch subject, ask for summary
                when /([A-Z]+\d?)/                     # step two : 
                    @adding_event[:subject] = $1.to_s  # got subject
                    delete_message(@adding_event.delete(:kbId))

                    # need summary
                    reponse("Add event in #$1.")
                    reponse("/#{@per_chat_bot.flag} Summary:", Telegram::Bot::Types::ForceReply.new(force_reply: true))
                    @adding_event[:wait_for_reply] = true
                when /change_month (\d+) (\d+)/
                    edit_ikb(@adding_event[:kbId], create_calendar_ikb($1, $2))
#---------- STEP 4: catch date, ask for starttime
                when /(\d{1,2})\.(\d{1,2})\.(\d{4})/
                    #reponse("Add event in #{@adding_event[:subject]} with summary:\n#{@adding_event[:summary]}\nFor the date #$1.#$2.#$3")
                    # clear
                    delete_message(@adding_event.delete(:kbId))
                    @adding_event[:date] = DateTime.new($3.to_i, $2.to_i, $1.to_i)
                    reponse("Date set to #$1.#$2.#$3.")
                    reponse("/#{@per_chat_bot.flag} Starttime (hh:mm):", Telegram::Bot::Types::ForceReply.new(force_reply: true))
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
                    when /Summary/ # we get subject & summary
                        # show kb for date
                        @adding_event.delete(:wait_for_reply)
                        kbId = generate_ikb("Which day ?", create_calendar_ikb(10, 2017))['result']['message_id']
                        @adding_event[:kbId] = kbId.to_s
                        @adding_event[:summary] = message.text
#---------- STEP 5: catch starttime, ask for duration
                    when /Starttime/
                        starttime = message.text.split(":")
                        @adding_event[:date] += Rational(starttime.first.to_f + starttime.last.to_f / 60, 24)
                        reponse("Time set to #{message.text}.")
                        reponse("/#{@per_chat_bot.flag} Duration in minutes (default 45):", Telegram::Bot::Types::ForceReply.new(force_reply: true))
#---------- STEP 6: catch duration, add event in cal
                    when /Duration/
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

        def listen_subscribe_event(message)
            if message.kind_of? Telegram::Bot::Types::CallbackQuery
                case message.data
                when /Done/
                    if @subscribe_event.key?(:kbId)
                        delete_message(@subscribe_event[:kbId])
                    end

                    @subscribe_event = Hash.new
                when /([A-Z]+\d?)/ # step two : 
                    @per_chat_bot.add_subscribe(@chat_id, $1.to_s)
                    @subscribe_event[:kb_content][0][@per_chat_bot.subject.index($1.to_s)][0] += " \u{2713}"
                    edit_ikb(@subscribe_event[:kbId].to_s, @subscribe_event[:kb_content])
                    # need summary
                    reponse("Add subscribe to #$1.")
                end
            else
                case message.text
                when 'q'
                    if @subscribe_event.key?(:kbId)
                        delete_message(@subscribe_event[:kbId])
                    end
                    @subscribe_event = Hash.new
                    reponse("Operation abort.")
                else
                    if @subscribe_event[:wait_for_reply]
                        reponse("Please REPLY to the message above or abort current operation with 'q'.")
                    end
                end
            end
        end
    end
end
