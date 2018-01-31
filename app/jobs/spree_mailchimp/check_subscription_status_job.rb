module SpreeMailchimp
  class CheckSubscriptionStatusJob < ApplicationJob
    queue_as :mailchimp

    def perform
      gibbon = Gibbon::Request.new(api_key: Rails.application.secrets.mailchimp_api_key)
      list_id = Rails.application.secrets.mailchimp_list_id || ''

      Spree::Subscription.synced.each do |subscription|
        member_info = begin
                        gibbon.lists(list_id).members(subscription.email_md5).retrieve.body
                      rescue StandardError
                        nil
                      end
        next if member_info.nil?

        if member_info['status'] == 'subscribed' && !subscription.subscribed?
          puts "Subscribe #{subscription.email}"
          # Trigger re-synchronization from Spree to Mailchimp by fully updating user
          subscription.user.update(receive_emails_agree: true)
        elsif member_info['status'] != 'subscribed' && subscription.subscribed?
          puts "Unsubscribe #{subscription.email}"
          # Prevent re-synchronization from Spree to Mailchimp by updating single user column without callbacks
          subscription.user.update_column(:receive_emails_agree, false)
          subscription.update(state: Spree::Subscription::STATE_UNSUBSCRIBED_SYNCED)
        end
      end
    rescue StandardError => error
      ExceptionNotifier.notify_exception(error, data: { msg: 'Check Subscription Status' })
      raise error
    end
  end
end
