require './per_chat_bot'
require './calendar'
require './admin'

class CalendarPerChatBot < PerChatBot
    prepend Adminable
   
    CONF_MIN = {"super_admin":"","admins":{},"invited_admin":{},"subjects":[],"subscribe":{}}
    
    attr_accessor :calendars, :config, :all, :channel, :listen_user, :listen_admin, :listen_super_admin

    def initialize(config_path, father_bot)
        super(config_path, "calendar", father_bot, "c")
        check_conf
        @all = Calendar.new('all', Array.new())
        @calendars = @config["subjects"].map{|sub| [ sub , Calendar.new( sub, [@all] ) ] }.to_h
        @channel = @config["channel"]
        @user_cmds.merge!({"ls" => :list, "subscribe" => :subscribe}.merge(@@user_cmds))
        @admin_cmds = @@admin_cmds.merge({"add_event" => :add_event})
        @super_admin_cmds = @@super_admin_cmds
    end

    def check_conf
        CONF_MIN.each do |k, v|
            unless @config.key? k.to_s then @config[k.to_s] = v end 
        end
        @config["subjects"].each do |sub|
            unless @config["subscribe"].key? sub.to_s then @config["subscribe"][sub.to_s] = [] end
        end
    end

    def name
        "Calendar bot"
    end
 
    def new_worker(chat_id)
        @workers[chat_id] = CalendarWorker.new(chat_id, self)
    end

    def get_method_usage(methode_name)
        eval "@@" + methode_name.to_s + "_usage"
    end

    def toggle_subscribe(chat_id, calendar)
        if @config["subscribe"][calendar.to_s].include? chat_id.to_s
            @config["subscribe"][calendar.to_s].delete chat_id.to_s
            false
        else
            @config["subscribe"][calendar.to_s] << chat_id.to_s
            true
        end
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

    @@list_usage = "- lists the content of the calendar \"CAL\"\n- lists the main calendar if \"CAL\" isn't specified"
    @@add_event_usage = "- start an adding event procedure"
    @@subscribe_usage = "- Manage our calendar's subscribe\n    -> Subscribe to a calendar show you all updates on it"

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
            @per_chat_bot.has_super_admin?
        end

        def create_calendar_ikb(month, year)
            @per_chat_bot.create_calendar_ikb(month, year)
        end

        def get_admin_cmds
            @per_chat_bot.get_admin_cmds
        end

        def get_super_admin_cmds
            @per_chat_bot.get_super_admin_cmds
        end
        

        def listen(message)
            if !@adding_event.empty?
                listen_adding_event(message)
            elsif !@subscribe_event.empty?
                listen_subscribe_event(message)
            else
                args = get_text(message).split(" ").drop(1) # Array : ["cmd", "arg1", ...]
                cmd = args.shift # cmd = "cdm" and args = ["arg1", ...]
                cmd = "def_cmd" if cmd == nil

                if super_admin?
                    exec_cmd(get_super_admin_cmds[cmd], message, args) if get_super_admin_cmds.key? cmd
                end

                if admin?
                    exec_cmd(get_admin_cmds[cmd], message, args) if get_admin_cmds.key? cmd
                end

                exec_cmd(get_user_cmds[cmd], message, args) if get_user_cmds.key? cmd
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
                        text = "Event add in #{@adding_event[:subject]};  Summary:\n#{@adding_event[:summary]}\n For the date #{@adding_event[:date]}, with duration #{duration}";
                        reponse(text);

                        @per_chat_bot.send_broadcast(@per_chat_bot.config["subscribe"][@adding_event[:subject].to_s], text)
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
                    delete_message(@subscribe_event[:kbId]) if @subscribe_event.key?(:kbId)
                    delete_message(@subscribe_event[:pop_id]) if @subscribe_event.key?(:pop_id)

                    @subscribe_event = Hash.new
                when /([A-Z]+\d?)/ # step two : 
                    if @per_chat_bot.toggle_subscribe(@chat_id, $1) # if adding
                        index = @per_chat_bot.config["subjects"].index($1.to_s)
                        @subscribe_event[:kb_content][index / 4][index % 4][0] += " \u{2713}"
                        edit_ikb(@subscribe_event[:kbId].to_s, @subscribe_event[:kb_content])
                        text = "Add subscribe to #$1"
                        if @subscribe_event.key? :pop_id
                            edit_message(@subscribe_event[:pop_id], text)
                        else
                            @subscribe_event[:pop_id] = reponse(text)['result']['message_id'] 
                        end
                    else # if removing
                        index = @per_chat_bot.config["subjects"].index($1.to_s)
                        @subscribe_event[:kb_content][index/4][index % 4][0] = $1
                        edit_ikb(@subscribe_event[:kbId].to_s, @subscribe_event[:kb_content])
                        text = "Remove subscribe to #$1."
                        if @subscribe_event.key? :pop_id
                            edit_message(@subscribe_event[:pop_id], text)
                        else
                            @subscribe_event[:pop_id] = reponse(text)['result']['message_id'] 
                        end
                    end
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

        def add_event(message, args)
            kbId = generate_ikb("Which class subject ?", (get_config["subjects"]+["Cancel"]).zip((get_config["subjects"]+["Cancel"])).each_slice(4).to_a)['result']['message_id']
            @adding_event = {kbId: kbId.to_s}
        end

        def subscribe(message, args)
            kb_subject = get_config["subjects"].collect { |sub| 
                (get_config["subscribe"][sub.to_s].include? get_id_from_message(messsage)) ? sub += " \u{2713}" : sub
            }
            kb_content = (kb_subject).zip((get_config["subjects"])).each_slice(4).to_a + [[["Done", "Done"]]]
            kbId = generate_ikb("Which subject do you want to subscribe to ?", kb_content)['result']['message_id']
            @subscribe_event = {kbId: kbId.to_s, kb_content: kb_content}
        end

        def list(message, args)
            text = get_text(message).sub("ls","")
            if args.empty?
                kb_subject = get_config["subjects"] 
                kb_content = (kb_subject).zip((kb_subject.map{ |sub| "ls " + sub })).each_slice(4).to_a + [[["All", "ls all"],["Cancel", "private_del_ikb"]]]
                del_ikb
                @unique_ikb = generate_ikb("Choose a subject to display the corresponding calendar's content:", kb_content)['result']['message_id']
                    
            elsif !["admins","invitations"].include?(args[0])
                args[0].to_s.upcase!
                if @per_chat_bot.calendars.key?(args[0])
                    reponseHTML("<a href=\"http://rasp-heig.ddns.net/calendars/#{args[0]}.ics\">#{args[0]}.ics</a> :\n" + @per_chat_bot.calendars[args[0]].list)
                elsif args[0] == "ALL"
                    reponseHTML("<a href=\"http://rasp-heig.ddns.net/calendars/all.ics\">all.ics</a> :\n" + @per_chat_bot.all.list)
                else
                    reponse(args[0] + " doesn't correspond to any calendar in the system.")
                end
            end
        end
        
    end
end
