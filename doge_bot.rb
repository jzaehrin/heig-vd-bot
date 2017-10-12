require './bot'

class DogeBot < Bot

    def initialize(api)
        super(api)
    end

    def listen(message)
        case message.text
        when '/doge'
            bot.api.send_photo(chat_id: message.chat.id, photo: "https://i.pinimg.com/736x/5e/47/a3/5e47a3c6c1f85255c9e32f294a3dd173--doge-meme-portal.jpg")
        when Telegram::Bot::Types::CallbackQuery
            # Here you can handle your callbacks from inline buttons
            if message.data == 'touch'
              bot.api.send_message(chat_id: message.from.id, text: "Don't touch me!")
            end
        when Telegram::Bot::Types::Message
            kb = [
              Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Go to Google', url: 'https://google.com'),
              Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Touch me', callback_data: 'touch'),
              Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Switch to inline', switch_inline_query: 'some text')
            ]
            markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
            bot.api.send_message(chat_id: message.chat.id, text: 'Make a choice', reply_markup: markup)
        end
    end
end
