class DogeBot < Bot

    def initialize(api)
        super(api)

        @client = Twitter::REST::Client.new do |config|
            config.consumer_key = "KEY"
            config.consumer_secret = "KEY"
        end
    end

    def listen(message)
        case message.text
        when /menu/
            if Time.now > Time.parse("10:00 am")
                tweets = @client.user_timeline("heig_cafeteria", {count: 3});

                tweets.each! do |v|
                    v = "- " + v
                end
                
                reponse(message.chat.id, tweets.join('\n'))
            else
                reponse(message.chat.id, "Before 10h, the cafeteria don't publish the menu on Twitter")
            end
        end
    end
end
