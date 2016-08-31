require 'wit'

class WitClient

  # initialize
  def initialize(wit_access_token)
    @access_token = wit_access_token
  end

  # understand text by wit.ai
  #
  # @param [String] text text to understand
  # @return [String, Hash] message, response which contains wit.ai context
  def run_actions(text)
    message = nil
    result = {}

    wit = Wit.new(
      access_token: @access_token,
      actions: {
        send: -> (request, response) {
          message = response['text']
        },
        :merge => -> (request) {
          entities = request['entities']
          return {} unless entities.is_a? Hash
          entities.each do |key, values|
            list = []
            values.each { |value| list.push value['value'] }
            result[key] = list
          end
          {}
        }
      }
    )
    session_id = "#{DateTime.now}"
    wit.run_actions(session_id, text, {})

    return message, result
  end

end
