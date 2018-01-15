namespace :spree do
  namespace :mailchimp do
    desc 'Check mailchimp status of synced used'
    task check_status: :environment do
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
          puts "Subscribe\t" + subscription.email
          subscription.update(state: Spree::Subscription::STATES_SUBSCRIBED)
          subscription.set_as_synced
        elsif member_info['status'] != 'subscribed' && subscription.subscribed?
          puts "Unsubscribe\t" + subscription.email
          subscription.update(state: Spree::Subscription::STATES_UNSUBSCRIBED)
          subscription.set_as_synced
        end
      end
    end
  end
end
