class CreateSubscribers < ActiveRecord::Migration
  create_table :spree_subscribers do |t|
    t.integer :user_id
    t.string :email
    t.string :first_name
    t.string :last_name
    t.string :source, default: ''
    t.integer :status
    t.timestamps null: true
  end

  add_column :spree_users, :receive_emails_agree, :boolean, default: false
end
