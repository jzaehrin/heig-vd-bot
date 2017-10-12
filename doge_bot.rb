require './bot'

class DogeBot < Bot

    def initialize(api)
        super(api)
    end

    def listen(message)
        case message.text
        when '/doge'
            bot.api.send_photo(chat_id: message.chat.id, photo: "https://i.pinimg.com/736x/5e/47/a3/5e47a3c6c1f85255c9e32f294a3dd173--doge-meme-portal.jpg")
        end
    end
end
