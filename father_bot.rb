require 'json'
require 'abstraction'

class FatherBot  < Bot
    include Adminable
    attr_reader :id, :api

    def initialize(config_path, id, logger)       
        @id = id
        @logger = logger
        @bots = Array.new
        @api
        super(config_path, "default", self, "f")
        @token = @config["token"]
        run
    end

    def add_bot(*bots)
        @bots.concat bots
    end

    def usage
        usage_bots = Array.new.concat(@bots.each |bot| bot.usage)

        <<~HEREDOC
            I'm the father of all Bot :
            - /help print this help
            #{usage_bots.join('\n')}
        HEREDOC
    end

    def run
        Telegram::Bot::Client.run(@token) do |bot|
            @bot = bot
            @api = bot.api
        end
    end

    def listen()
        begin
            @logger.info('listen') { "Start listening for messages..." }
            @bot.listen do |message|
                @logger.debug('listen') { "Get message : \"#{message}\", dispatch." }
                text = message.respond_to?(:text) ? message.text : message.data
                # catch string "q" to abort any ongoing operation
                if text == 'q'
                    @bots.each do |bot|
                        bot.listen(message)
                    end
                # normal listen process
                else 
                    # if message is a reply, catch flag in original text message
                    text = message.reply_to_message.text if message.respond_to?(:reply_to_message) && !message.reply_to_message.nil?
                    case text 
                    when /^\/f (.*)/
                        @logger.debug('listen') { "Dispatched to \"father bot\"." }
                        listen_father(message)
                    when /^\/(\w+)/
                        @bots.each do |bot|
                            # dispatch where the flag correspond
                            if bot.flag == $1
                                @logger.debug('listen') { "Dispatched to bot \"#{bot.name}.\"" }
                                bot.listen(message)
                            end
                        end
                    else
                        listen_father(message)
                    end
                end
            end
        rescue SystemExit, Interrupt
            #Destroy bots
            @logger.warn('System interrupt') { "A SINGTERM has been catched. Destroying bots and father bot..." }
            close           
        rescue StandardError => e
            @logger.error('Response Error') { "Api say : #{e.message}" }
            close
        end
    end

    def listen_father(message)
        case message
        when /\/help/
            usage
        end
    end

    def close
        @logger.close
        @bots.each do |bot|
            bot.destroy
        end
        destroy
    end
end
