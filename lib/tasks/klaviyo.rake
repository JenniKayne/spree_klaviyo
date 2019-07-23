namespace :spree do
  namespace :klaviyo do
    desc 'Check klaviyo status of synced used'
    task check_status: :environment do
      SpreeKlaviyo::CheckSubscriptionStatusJob.perform_now
    end

    desc 'Schedule: Check Klaviyo status of synced used'
    task schedule_check_status: :environment do
      SpreeKlaviyo::CheckSubscriptionStatusJob.perform_later
    end
  end
end
