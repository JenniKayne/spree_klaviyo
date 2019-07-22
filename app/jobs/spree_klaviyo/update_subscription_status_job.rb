module SpreeKlaviyo
  class UpdateSubscriptionStatusJob < ApplicationJob
    queue_as :klaviyo

    def perform(subscription)
      if subscription.subscribed?
        if double_opt_in?
          client.subscribe(list_id, subscription.klaviyo_body)
        else
          client.add_to_list(list_id, subscription.klaviyo_body)
        end
      else
        client.unsubscribe(list_id, subscription.email)
        client.remove_from_list(list_id, subscription.email)
      end

      subscription.set_as_synced
    rescue StandardError => error
      Raven.extra_context msg: 'Klaviyo subscription error (#{subscription.email})'
      Raven.capture_exception(error)

      raise error
    end

    private

    def client
      @client ||= Klaviyo::Client.new
    end

    def list_id
      Rails.application.secrets.klaviyo_list_id || ''
    end

    def double_opt_in?
      Rails.application.secrets.klaviyo_double_opt_in
    end
  end
end
