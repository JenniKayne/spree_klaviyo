module SpreeMailchimp
  class UpdateSubscriptionStatusJob < ApplicationJob
    queue_as :mailchimp

    def perform(subscription)
      gibbon = Gibbon::Request.new(api_key: Rails.application.secrets.mailchimp_api_key)
      list_id = Rails.application.secrets.mailchimp_list_id || ''
      email_md5 = Digest::MD5.hexdigest subscription.email.downcase

      if subscription.subscribed?
        member_info = begin
                        gibbon.lists(list_id).members(email_md5).retrieve.body
                      rescue StandardError
                        nil
                      end
        if member_info.nil?
          # Create a new subscription
          gibbon.lists(list_id).members.create(body: subscription.mailchimp_request_body)
        else
          # Update subscription
          gibbon.lists(list_id).members(email_md5).update(body: subscription.mailchimp_request_body)
        end
      else
        # Unsubscribe
        gibbon.lists(list_id).members(email_md5).update(body: { status: 'unsubscribed' })
      end

      subscription.set_as_synced
    rescue StandardError => error
      ExceptionNotifier.notify_exception(error, data: { msg: "Mailchimp Error (#{subscription.email})" })
      raise error
    end
  end
end
