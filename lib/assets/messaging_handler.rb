require './lib/assets/wit_client'
require './lib/assets/facebook_client'


class MessagingHandler

  # constants

  # text
  GREETING_TEXT ||= 'Hi, there! Welcome to Westfield Centre. Let me know if you need any help.'
  THANKS_TEXT ||= 'Thanks for asking. See you soon!'

  # postback
  STOP_POSTBACK ||= 'stop'
  CALL_POSTBACK ||= 'call_'


  # initialize
  #
  # @param [String] sender_id facebook user id
  def initialize(sender_id)
    @sender = Sender.find_by_facebook_id(sender_id)
    unless @sender
      @sender = Sender.new
      @sender.facebook_id = sender_id
      @sender.save if @sender.valid?
    end

    @wit_client = WitClient.new(ENV['WIT_ACCESS_TOKEN'])
    @facebook_client = FacebookClient.new(sender_id)
  end


  # handle json which came from facebook messenger platform
  #
  # @param [Hash] json hash
  def handle_json(json)
    begin
      messaging = json['entry'][0]['messaging'][0]
    rescue => e
    end

    # stop bot
    if check_if_stop_bot_by_messaging(messaging)
      stop(json)
      return

    # find a bot to introduce
    elsif @sender.bot_id == nil
      bot_name = get_bot_name_by_messaging(messaging)
      call_bot_by_name(bot_name)
    end

    # forward json if there is introduced bot
    if @sender.bot_id
      json = botyou(json)
      if json && json['facebook']
        js = json['facebook']
        js.each { |j| @facebook_client.post_json(j) }
      end

    else
      @facebook_client.post_text(GREETING_TEXT)

    end
  end


  # handle messaging, and get if stop bot
  #
  # @param [Hash] messaging hash
  # @return [Bool] if stop bot
  def check_if_stop_bot_by_messaging(messaging)
    # message
    if messaging.include?('message')
      message = messaging['message']
      # text
      if message.include?('text')
        text = "#{message['text']}".downcase
        return true if text == 'stop'
      end

    # postback
    elsif messaging.include?('postback')
      payload = messaging['postback']['payload']
      return true if payload == STOP_POSTBACK
    end

    false
  end

  # handle messaging, and get bot name you need
  #
  # @param [Hash] messaging hash
  # @return [String] bot's name
  def get_bot_name_by_messaging(messaging)
    bot_name = nil

    # message
    if messaging.include?('message')
      message = messaging['message']
      # text
      if message.include?('text')
        text = "#{message['text']}".downcase

        # wit.ai
        message, contexts = @wit_client.run_actions(text)
        bot_name = message.sub(CALL_POSTBACK, '') if message.start_with?(CALL_POSTBACK)
      end

    # postback
    elsif messaging.include?('postback')
      payload = messaging['postback']['payload']
      bot_name = payload.sub(CALL_POSTBACK, '') if payload.start_with?(CALL_POSTBACK)
    end

    bot_name
  end


  # call bot by name
  #
  # @param bot_name bot's name
  def call_bot_by_name(bot_name)
    bot = Bot.find_by_name(bot_name)
    return unless bot
    return unless bot.uri

    @sender.bot_id = bot.id
    @sender.save if @sender.valid?
  end

  # foward json to another bot
  #
  # @param bot_name bot's name
  # @return [Hash] json to send to facebook server
  def botyou(json)
    bot = Bot.find_by_id(@sender.bot_id)
    return unless bot

    @facebook_client.botyou(bot.uri, {'verify_token' => bot.verify_token}, json) if bot.uri
  end

  # stop
  #
  # @param [Hash] json to forward
  def stop(json)
    bot = Bot.find_by_id(@sender.bot_id)
    @facebook_client.botme(bot.uri, {'verify_token' => bot.verify_token}, json) if bot

    @sender.bot_id = nil
    @sender.save if @sender.valid?

    @facebook_client.post_text(THANKS_TEXT)
  end

end
