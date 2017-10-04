
require 'rubygems'
require 'telegram/bot'

token = '456606561:AAHmqy8Dg91l1xbSNpxMQgZiFc6mvQPpemw'

Telegram::Bot::Client.run(token) do |bot|
  bot.listen do |message|
    case message.text
    when '/start'
      bot.api.send_message(chat_id: message.chat.id, text: "Hello, #{message.from.first_name}!")
    when '/doge'
      bot.api.send_photo(chat_id: message.chat.id, photo: "https://i.pinimg.com/736x/5e/47/a3/5e47a3c6c1f85255c9e32f294a3dd173--doge-meme-portal.jpg")
    else
      bot.api.send_message(chat_id: message.chat.id, text: "Je ne vous comprends pas ! :(")
    end
  end
end