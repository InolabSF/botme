require 'faraday'
require 'json'


class FacebookClient

  # initialize
  #
  # @param [String] sender_id messenger user ID
  def initialize(sender_id)
    @access_token = ENV['FB_ACCESS_TOKEN']
    @sender_id = sender_id
  end


  # post message to facebook messenger
  #
  # @param [Hash] message message to send (https://developers.facebook.com/docs/messenger-platform/send-api-reference#request)
  # @return [Hash] response
  def post_message(message)
    uri_string = 'https://graph.facebook.com/v2.6/me/messages'
    connection = Faraday.new(:url => uri_string) do |faraday|
      faraday.request  :url_encoded
      faraday.response :logger
      faraday.adapter  Faraday.default_adapter
    end

    response = connection.post do |request|
      request.params['access_token'] = @access_token
      request.headers['Content-Type'] = 'application/json'
      request.body = { :recipient => { :id => @sender_id }, :message => message }.to_json
    end

    begin
      JSON.parse(response.body)
    rescue Exception => e
      {}
    end
  end

  # post text to facebook messenger
  #
  # @param [String] text text to send
  # @return [Hash] response
  def post_text(text)
    post_message({ :text => text }) if text
  end

  # post button
  #
  # @param [Array] buttons button titles
  # @param [Array] payloads button payloads
  # @return [Hash] response
  def post_button(buttons, payloads)
    # request body
    button_hashes = []
    buttons.each_with_index do |button, j|
      p = (payloads) ? payloads[j] : nil
      p = button if p.blank?
      button_hashes.push({ :type => 'postback', :title => button, :payload => p })
    end
    message = {
      :attachment => {
        :type => 'template',
        :payload => {
          :template_type => 'button',
          :text => '　',
          :buttons => button_hashes
        }
      }
    }

    # post
    post_message(message)
  end

  # post an element to facebook messenger
  #
  # @param [String] title element title
  # @param [String] subtitle element subtitle
  # @param [String] image_uri element image_uri
  # @param [Array] buttons button titles
  # @param [Array] payloads button payloads
  # @return [Hash] response
  def post_element(title, subtitle, image_uri, buttons, payloads)
    post_elements([title], [subtitle], [image_uri], [buttons], [payloads])
  end

  # post elements to facebook messenger
  #
  # @param [Array] titles elements' title
  # @param [Array] subtitles elements' subtitle
  # @param [Array] image_uris elements' image_uri
  # @param [Array] buttons_list button titles' array
  # @param [Array] payloads_list button payloads' array
  # @return [Hash] response
  def post_elements(titles, subtitles, image_uris, buttons_list, payloads_list)
    # request body
    message = {
      :attachment => {
        :type => 'template',
        :payload => {
          :template_type => 'generic',
          :elements => [ ]
        }
      }
    }
    elements = message[:attachment][:payload][:elements]
    titles.each_with_index do |title, i|
      subtitle = (subtitles) ? subtitles[i] : nil
      image_uri = (image_uris) ? image_uris[i] : nil
      buttons = (buttons_list) ? buttons_list[i] : nil
      payloads = (payloads_list) ? payloads_list[i] : nil

      element = {}
      element[:title] = title if title
      element[:subtitle] = subtitle if subtitle
      element[:image_url] = image_uri if image_uri
      if buttons
        button_hashes = []
        buttons.each_with_index do |button, j|
          p = (payloads) ? payloads[j] : nil
          p = button if p.blank?
          button_hashes.push({ :type => 'postback', :title => button, :payload => p })
        end
        element[:buttons] = button_hashes if button_hashes.count
      end
      elements.push element
    end
    # post
    post_message(message)
  end

  # post elements to facebook messenger
  #
  # @param [Array] messages Array of Hash to send
  # @return [Hash] response
  def post_elements_by_list(messages)
    # request body
    message = {
      :attachment => {
        :type => 'template',
        :payload => {
          :template_type => 'generic',
          :elements => [ ]
        }
      }
    }
    elements = message[:attachment][:payload][:elements]
    messages.each do |message|
      title = (message['title']) ? message['title'] : nil
      subtitle = (message['subtitle']) ? message['subtitle'] : nil
      image_uri = (message['image_uri']) ? (message['image_uri']) : nil
      buttons = (message['buttons']) ? message['buttons'] : nil
      payloads = (message['payloads']) ? message['payloads'] : nil

      element = {}
      element[:title] = title if title
      element[:subtitle] = subtitle if subtitle
      element[:image_url] = image_uri if image_uri
      if buttons
        button_hashes = []
        buttons.each_with_index do |button, j|
          p = (payloads) ? payloads[j] : nil
          p = button if p.blank?
          button_hashes.push({ :type => 'postback', :title => button, :payload => p })
        end
        element[:buttons] = button_hashes if button_hashes.count
      end
      elements.push element
    end
    # post
    post_message(message)
  end


  # get user graph
  #
  # @return [Hash] response which contains first_name, last_name, gender, locale, and timezone
  def get_graph
    uri_string = "https://graph.facebook.com/v2.6/#{@sender_id}"
    connection = Faraday.new(:url => uri_string) do |faraday|
      faraday.request  :url_encoded
      faraday.response :logger
      faraday.adapter  Faraday.default_adapter
    end

    response = connection.get do |request|
      request.params['access_token'] = @access_token
      request.headers['Content-Type'] = 'application/json'
    end

    begin
      JSON.parse(response.body)
    rescue Exception => e
      {}
    end
  end


  # forward json to another bot server
  #
  # @param [String] uri uri to send
  # @param [Hash] params query to send
  # @param [Hash] json json to send
  # @return [Hash] response
  def forward_json(uri, params, json)
    connection = Faraday.new(:url => uri) do |faraday|
      faraday.request  :url_encoded
      faraday.response :logger
      faraday.adapter  Faraday.default_adapter
    end

    response = connection.post do |request|
      request.params = params
      request.headers['Content-Type'] = 'application/json'
      request.body = json.to_json
    end

    begin
      JSON.parse(response.body)
    rescue Exception => e
      {}
    end
  end

  # post json to facebook messenger
  #
  # @param [Hash] json to send
  # @return [Hash] response
  def post_json(json)
    uri_string = 'https://graph.facebook.com/v2.6/me/messages'
    connection = Faraday.new(:url => uri_string) do |faraday|
      faraday.request  :url_encoded
      faraday.response :logger
      faraday.adapter  Faraday.default_adapter
    end

    response = connection.post do |request|
      request.params['access_token'] = @access_token
      request.headers['Content-Type'] = 'application/json'
      request.body = json.to_json
    end

    begin
      JSON.parse(response.body)
    rescue Exception => e
      {}
    end
  end


end
