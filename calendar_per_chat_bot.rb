require './per_chat_bot'
require './calendar'

class CalendarPerChatBot < PerChatBot

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
            when '/myUsername'
                reponse(message.from.username.to_s)
            when '/add_event'
                kbId = generate_ikb("Which class subject ?", @@subject.zip(@@subject).each_slice(3).to_a)['result']['message_id']
                @adding_event = {kbId: kbId.to_s}
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
