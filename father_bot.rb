require 'json'
require 'abstraction'

class FatherBot  < Bot
    include Adminable
    attr_reader :id, :api

    def initialize(config_path, id)       
        @id = id
        @api
        super(config_path, "default", self, "f")
        @token = @config["token"]
        run
    end

    def run
        Telegram::Bot::Client.run(@token) do |bot|
            @bot = bot
            @api = bot.api
        end
    end

    def listen(*bots)
        begin
            @bot.listen do |message|
                text = message.respond_to?(:text) ? message.text : message.data
                # catch string "q" to abort any ongoing operation
                if text == 'q'
                    bots.each do |bot|
                        bot.listen(message)
                    end
                # normal listen process
                else 
                    # if message is a reply, catch flag in original text message
                    text = message.reply_to_message.text if message.respond_to?(:reply_to_message) && !message.reply_to_message.nil?
                    case text 
                    when /^\/f (.*)/
                        listen_father(message) 
                    when /^\/(\w+)/
                        bots.each do |bot|
                            # dispatch where the flag correspond
                            if bot.flag == $1
                                bot.listen(message)
                            end
                        end
                    end
                end
            end
        rescue SystemExit, Interrupt
            #Destroy bots
            bots.each do |bot|
                bot.destroy
            end
            destroy
        end
    end

    def listen_father(message)
        TODO
    end
end
