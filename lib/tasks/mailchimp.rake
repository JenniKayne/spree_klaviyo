namespace :spree do
  namespace :mailchimp do
    desc "Send emails"
    task send_emails: :environment do
      gibbon = Gibbon::Request.new(api_key: Rails.application.secrets.mailchimp_api_key)
      list_id = Rails.application.secrets.mailchimp_list_id || ''

      Spree::Subscriber.not_synced.each do |subscriber|
        email_md5 = Digest::MD5.hexdigest subscriber.email.downcase

        if subscriber.subscribed?
          puts "Subscribe\t" + subscriber.email
          begin
            member_info = gibbon.lists(list_id).members(email_md5).retrieve
          rescue
            member_info = nil
          end

          if member_info.nil?
            request_body = {
              email_address: subscriber.email,
              status: "subscribed",
              double_optin: false,
              update_existing: true
            }

            merge_fields = {}
            if !subscriber.first_name.nil? && !subscriber.first_name.empty?
              merge_fields[:FNAME] = subscriber.first_name
            end
            if !subscriber.last_name.nil? && !subscriber.last_name.empty?
              merge_fields[:LNAME] = subscriber.last_name
            end
            if !subscriber.source.nil? && !subscriber.source.empty?
              merge_fields[:SOURCE] = subscriber.source
            end
            if !merge_fields.empty?
              request_body[:merge_fields] = merge_fields
            end

            begin
              gibbon.lists(list_id).members.create(body: request_body)
            rescue
              puts "Subscription error"
            end
          else
            begin
              gibbon.lists(list_id).members(email_md5).update(body: { status: "subscribed" })
            rescue
              puts "Resubscription error"
            end
          end
        else
          puts "Unubscribe\t" + subscriber.email
          begin
            gibbon.lists(list_id).members(email_md5).update(body: { status: "unsubscribed" })
          rescue
            puts "Unsubscription error"
          end
        end

        subscriber.synced!
      end
    end

    desc "Check mailchimp status"
    task sync: :environment do
      gibbon = Gibbon::Request.new(api_key: Rails.application.secrets.mailchimp_api_key)
      list_id = Rails.application.secrets.mailchimp_list_id || ''

      Spree::Subscriber.synced.each do |subscriber|
        email_md5 = Digest::MD5.hexdigest subscriber.email.downcase
        begin
          reponse = gibbon.lists(list_id).members(email_md5).retrieve
          member_info = reponse.body
        rescue
          member_info = nil
        end

        if !member_info.nil?
          if member_info['status'] == 'subscribed' && !subscriber.subscribed?
            puts "Sync and subscribe\t" + subscriber.email
            subscriber.subscribe true
            subscriber.synced!
          elsif member_info['status'] != 'subscribed' && subscriber.subscribed?
            puts "Sync and unsubscribe\t" + subscriber.email
            subscriber.subscribe false
            subscriber.synced!
          end

          if !subscriber.user_id.nil?
            user = subscriber.user
            if user.receive_emails_agree != subscriber.subscribed?
              user.receive_emails_agree = subscriber.subscribed?
              user.save
            end
          end
        end
      end
    end
  end
end
