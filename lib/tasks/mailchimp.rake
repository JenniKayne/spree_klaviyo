namespace :spree do
  namespace :mailchimp do
    desc 'Check mailchimp status of synced used'
    task check_status: :environment do
      SpreeMailchimp::CheckSubscriptionStatusJob.perform_now
    end

    desc 'Schedule: Check mailchimp status of synced used'
    task schedule_check_status: :environment do
      SpreeMailchimp::CheckSubscriptionStatusJob.perform_later
    end
  end
end
