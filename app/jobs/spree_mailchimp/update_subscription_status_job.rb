module SpreeMailchimp
  class UpdateSubscriptionStatusJob < ApplicationJob
    queue_as :mailchimp

    def gibbon
      @gibbon ||= Gibbon::Request.new(api_key: Rails.application.secrets.mailchimp_api_key)
    end

    def list_id
      Rails.application.secrets.mailchimp_list_id || ''
    end

    def perform(subscription)
      if subscription.subscribed?
        member_info = begin
                        gibbon.lists(list_id).members(subscription.email_md5).retrieve.body
                      rescue StandardError
                        nil
                      end
        if member_info.nil?
          # Create a new subscription
          gibbon.lists(list_id).members.create(body: subscription.mailchimp_request_body)
        else
          # Update subscription
          perform_subscription_update(subscription)
        end
      else
        # Unsubscribe
        gibbon.lists(list_id).members(subscription.email_md5).update(body: { status: 'unsubscribed' })
      end

      subscription.set_as_synced
    rescue StandardError => error
      ExceptionNotifier.notify_exception(error, data: { msg: "Mailchimp Error (#{subscription.email})" })
      raise error
    end

    def perform_subscription_update(subscription)
      gibbon.lists(list_id).members(subscription.email_md5).update(body: subscription.mailchimp_request_body)
    rescue Gibbon::MailChimpError
      # Sync back with Mailichimp on error
      if mailchimp_subscribed?(subscription)
        subscription.user.update_column(:receive_emails_agree, true) if subscription.user.present?
        subscription.update_column(:state, Spree::Subscription::STATE_SUBSCRIBED_SYNCED)
      else
        subscription.user.update_column(:receive_emails_agree, false) if subscription.user.present?
        subscription.update_column(:state, Spree::Subscription::STATE_UNSUBSCRIBED_SYNCED)
      end
    end

    def mailchimp_subscribed?(subscription)
      member_info = gibbon.lists(list_id).members(subscription.email_md5).retrieve.body
      member_info['status'] == 'subscribed'
    rescue StandardError
      false
    end
  end
end
