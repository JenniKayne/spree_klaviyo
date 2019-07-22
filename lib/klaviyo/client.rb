require 'httparty'
require 'base64'
require 'json'

module Klaviyo
  class KlaviyoError < StandardError; end

  class Client
    API_URL = 'https://a.klaviyo.com'

    def initialize(api_key=nil)
      @api_key = api_key || Rails.application.secrets.klaviyo_api_key || ENV['KLAVIYO_API_KEY']
    end

    def add_to_list(list_id, profiles)
      JSON.parse(post("/api/v2/list/#{list_id}/members", profiles: profiles).body)
    end

    def remove_from_list(list_id, emails)
      delete("/api/v2/list/#{list_id}/members", emails: emails)
    end

    def fetch_list_member(list_id, email)
      JSON.parse(get("/api/v2/list/#{list_id}/members", emails: email).body).first
    end

    def email_on_the_list?(list_id, email)
      member = fetch_list_member(list_id, email)

      member && member['email'] == email
    end

    def subscribe(list_id, profiles)
      JSON.parse(post("/api/v2/list/#{list_id}/subscribe", profiles: profiles).body)
    end

    def unsubscribe(list_id, email)
      delete("/api/v2/list/#{list_id}/subscribe", emails: email)
    end

    def fetch_list_subscription(list_id, email)
      JSON.parse(get("/api/v2/list/#{list_id}/subscribe", emails: email).body).first
    end

    def email_subscribed?(list_id, email)
      subscription = fetch_list_subscription(list_id, email)

      subscription && subscription['email'] == email
    end

    private

    attr_accessor :api_key

    def get(endpoint, params={})
      HTTParty.get("#{API_URL}#{endpoint}", {
        query: params,
        headers: { 'api-key' => api_key }
      })
    end

    def post(endpoint, params={})
      HTTParty.post("#{API_URL}#{endpoint}", {
        body: params.to_json,
        headers: {
          'api-key' => api_key,
          'Content-Type' => 'application/json'
        }
      })
    end

    def delete(endpoint, params={})
      HTTParty.delete("#{API_URL}#{endpoint}", {
        query: params,
        headers: { 'api-key' => api_key }
      })
    end
  end
end
