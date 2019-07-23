module SpreeKlaviyo
  class CheckSubscriptionStatusJob < ApplicationJob
    queue_as :klaviyo

    def perform
      Spree::Subscription.synced.each do |subscription|
        member_info = client.fetch_list_member(list_id, subscription.email)

        if member_info && !subscription.subscribed?
          puts "Subscribe #{subscription.email}"
          # Trigger re-synchronization from Spree to Mailchimp by fully updating user
          if subscription.user.present?
            subscription.user.update(receive_emails_agree: true)
          else
            subscription.update(state: Spree::Subscription::STATE_SUBSCRIBED_SYNCED)
          end
        else
          puts "Unsubscribe #{subscription.email}"
          # Prevent re-synchronization from Spree to Mailchimp by updating single user column without callbacks
          subscription.user.update_column(:receive_emails_agree, false) if subscription.user.present?
          subscription.update(state: Spree::Subscription::STATE_UNSUBSCRIBED_SYNCED)
        end
      end
    rescue StandardError => error
      Raven.extra_context msg: 'Checking Subscription Status'
      Raven.capture_exception(error)

      raise error
    end
  end

  private

  def list_id
    @list_id ||= Rails.application.secrets.klaviyo_list_id || ''
  end

  def client
    @client ||= Klaviyo::Client.new
  end
end
