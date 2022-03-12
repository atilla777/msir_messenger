# frozen_string_literal: true

module Msir
  class Sender
    def self.process(message)
      Telegram::Bot::Client.run(Msir.config.telegram_token) do |bot|
        bot.api.send_message(chat_id: Msir.config.telegram_chat_id, text: message) 
        Msir.logger.write(:info, 'Message sent')
      end
    end
  end
end
