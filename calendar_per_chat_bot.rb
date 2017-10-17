require './per_chat_bot'
require './calendar'
require './admin'

class CalendarPerChatBot < PerChatBot
    include Adminable

    def initialize(config_path, api)
        super(config_path, "calendar", api)
    end

    def new_worker(chat_id)
        @workers = {chat_id => CalendarWorker.new(chat_id,self)}
    end
    
    class CalendarWorker < PerChatBot::Worker

        @@subject = ['INF1', 'ARO1', 'WTF3']
        @@days_header = [['Mon','Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].zip([' ']*7)]

        def initialize(chat_id, per_chat_bot)
            super(chat_id, per_chat_bot)
            @adding_event = Hash.new
            @admin = @per_chat_bot.admin?(@chat_id.to_s)
        end

        def listen(message)
            if @adding_event.empty?
                super(message)
            else
                listen_adding_event(message)
            end
        end

        def listen_text(message)
            case message.text
            when '/ok'
                reponse("ko")
            when '/myId'
                reponse(message.from.id.to_s+" "+@chat_id.to_s)
            when /\/isAdmin (.+)/ # test with chat id
                case $1
                when /^(\d+)/
                    reponse(@per_chat_bot.admin?($1))
                when /^([a-zA-Z0-9]{4,})/ # test with username
                    reponse(@per_chat_bot.username_admin?($1))
                end
            when /\/ls (.+)/ # test with chat id
                case $1
                when 'admins'
                    text = "Admins list:\nusername\tchat_id\n"
                    @per_chat_bot.list_admins().each{|admin| text+= admin.first + "\t" + admin.last + "\n"}
                    reponse(text)
                when 'invitations'
                    text = "Admins invitations list:\nusername\tchat_id\n" + @per_chat_bot.list_invited_admin().to_s
                    reponse(text)
                end
            when '/myUsername'
                reponse(message.from.username.to_s)
            when '/add_event'
                kbId = generate_ikb("Which class subject ?", @@subject.zip(@@subject).each_slice(3).to_a)['result']['message_id']
                @adding_event = {kbId: kbId.to_s}
            when /\/add_admin ([a-zA-Z0-9]{4,})/
                if @admin 
                     
                    o = [('a'..'z'), ('A'..'Z'), ('0'..'9')].map(&:to_a).flatten
                    password = (0...8).map { o[rand(o.length)] }.join
                    @per_chat_bot.add_admin($1,password)
                    reponse("#$1 invited with key #{password.to_s}.")
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
            if message.kind_of? Telegram::Bot::Types::CallbackQuery then
                case message.data
                when 'test'
                    reponse("ko")
                when /^([A-Z]+\d)/
                    @adding_event.merge({subject: $1})
                    delete_kb(@adding_event[:kbId])
                    # use reponse
                    reponse("/add_event #$1 SUMMARY", Telegram::Bot::Types::ForceReply.new(force_reply: true))
                end
            else
                case message.text
                when 'hello'
                    nil
                end
            end
        end
    end
end
