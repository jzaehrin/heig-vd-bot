require 'json'
require 'abstraction'

class FatherBot  < Bot
    include Adminable # only include, do NOT want to override method :usage
    attr_reader :id, :api

    def initialize(config_path, id, logger)       
        @id = id
        @logger = logger
        @bots = Array.new
        super(config_path, "default")
        @token = @config["token"]
        run
    end

    def add_bot(*bots)
        @bots.concat bots
    end
    
    def name
        "Father bot"
    end

    def usage(chat_id)
        usage_bots = Array.new.concat(@bots.map{|bot| bot.name + ":\n" + bot.short_usage})

        <<~HEREDOC
            I'm the father in control of all bots:
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

    def listen
        begin
            @logger.info('listen') { "Start listening for messages..." }
            @bot.listen do |message|
                text = get_text(message)
                @logger.debug('listen') { "Get message : \"#{text}\", dispatch." }
                # catch string "q" to abort any ongoing operation
                if text == 'q'
                    @bots.each do |bot|
                        bot.listen(message)
                    end
                # normal listen process
                else 
                    # if message is a reply, catch flag in original text message
                    text = message.reply_to_message.text if message.respond_to?(:reply_to_message) && !message.reply_to_message.nil?
                    foundFlag = false
                    case text 
                    when /^\/(\w+)/
                        @bots.each do |bot|
                            # dispatch where the flag correspond
                            if bot.flag == $1
                                @logger.debug('listen') { "Dispatched to bot \"#{bot.name}.\"" }
                                bot.listen(message)
                                foundFlag = true
                                break
                            end
                        end
                    end

                    unless foundFlag 
                        @logger.debug('listen') { "Dispatched to \"father bot\"." }
                        listen_father(text, get_id_from_message(message))
                    end
                end
            end
        end
    end

    def listen_father(text, chat_id)
        case text
        when /\/help/
            reponseHTML(chat_id, usage(chat_id))
        when /\/start/
            buttons = Array.new(@bots.map{ |bot| [[bot.name,"/" + bot.get_flag + " start"]] }) << [["Cancel", "Cancel"]]
            generate_ikb(chat_id, "Choose a bot to work with:", buttons)
        when /Cancel kbId:([0-9]+)/
            delete_message(chat_id, $1)
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

