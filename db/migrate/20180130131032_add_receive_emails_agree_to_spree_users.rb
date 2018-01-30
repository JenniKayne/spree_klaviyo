class AddReceiveEmailsAgreeToSpreeUsers < ActiveRecord::Migration[5.1]
  add_column :spree_users, :receive_emails_agree, :boolean, default: false
end
