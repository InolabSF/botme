require './lib/assets/messaging_handler'


class WebhookController < ApplicationController

  skip_before_filter :verify_authenticity_token


=begin
  @apiVersion 0.1.0

  @apiGroup Webhook
  @api {get} /webhook/facebook
  @apiName Webhook#get_facebook
  @apiDescription webhook which does valification with facebook messenger platform

  @apiParam {Number} hub.verify_token           Mandatory text for valification
  @apiParam {Number} hub.challenge              Mandatory text for webhook

  @apiParamExample {text} Request-Example:
    hub.challenge text

  @apiSuccessExample {text} Success-Response:
    hub.challenge text

=end
  def get_facebook
    verify_token = params['hub.verify_token']
    render text: 'no verify_token' and return unless verify_token == ENV['FB_VERIFY_TOKEN']
    challenge = params['hub.challenge']
    render text: 'no challenge' and return unless challenge

    render text: challenge
  end


=begin
  @apiVersion 0.1.0

  @apiGroup Webhook
  @api {post} /webhook/facebook
  @apiName Webhook#post_facebook
  @apiDescription webhook which receives text message from facebook messenger platform


  @apiParamExample {json} Message-Text:
    {
      "entry" : [
        { "messaging" : [ {
            "sender" : {
              "id" : "123456789"
            },
            "message" : {
              "text" : "I am hungry"
            }
          } ]
        }
      ]
    }

  @apiParamExample {json} Postback-Payload:
    {
      "entry" : [
        { "messaging" : [ {
            "sender" : {
              "id" : "123456789"
            },
            "postback" : {
              "payload" : "issue_question:openaccount_today"
            }
          } ]
        }
      ]
    }

  @apiParamExample {json} Optin-Ref:
    {
      "entry" : [
        { "messaging" : [ {
            "sender" : {
              "id" : "123456789"
            },
            "optin" : {
              "ref" : "issue_question=openaccount:context=ios:timestamp=20160716T100000+0700"
            }
          } ]
        }
      ]
    }

  @apiParamExample {json} Message-Attachments-Location:
    {
      "entry" : [
        { "messaging" : [ {
            "sender" : {
              "id" : "123456789"
            },
            "message" : {
              "attachments" : {
                "type": "location",
                "payload": {
                  "coordinates": {
                    "lat": 37.787336343928,
                    "long": -122.40377439126
                   }
                }
              }
            }
          } ]
        }
      ]
    }


  @apiSuccessExample {json} Success-Response:
    {
    }

=end
  def post_facebook
    begin
      messaging = params['entry'][0]['messaging'][0]
      raise "messaging is needed" unless messaging

      facebook_id = messaging['sender']['id']
      raise "facebook(sender) id is needed" unless facebook_id

    rescue => e
      json = {"result" => "error", "message" => e.message}
      render :json => json, :status => 400
      return
    end

    messaging_handler = MessagingHandler.new(facebook_id)
    messaging_handler.handle_json(params)
    #messaging_handler.handle_on_facebook(messaging)

    json = {"result" => "success"}
    render json: json
  end


end
