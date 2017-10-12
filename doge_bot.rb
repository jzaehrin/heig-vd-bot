require './bot'

class DogeBot < Bot

    def initialize(api)
        super(api)
    end

    def listen(message)
        case message
        when Telegram::Bot::Types::CallbackQuery
        # Here you can handle your callbacks from inline buttons
            if message.data == 'touch'
              reponseFrom(message, "Don't touch me!")
            end
        when message.respond_to?('text') && message.text == 'caca'
            kb = [
              Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Go to Google', url: 'https://google.com'),
              Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Touch me', callback_data: 'touch'),
              Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Switch to inline', switch_inline_query: 'some text')
            ]
            markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
            reponse(message, 'Make a choice', markup)
        end
    end
end
