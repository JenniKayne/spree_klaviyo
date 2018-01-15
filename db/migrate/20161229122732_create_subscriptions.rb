class CreateSubscriptions < ActiveRecord::Migration[5.1]
  create_table :spree_subscriptions do |t|
    t.integer :user_id
    t.string :email
    t.string :source, default: ''
    t.string :state, default: :new
    t.timestamps null: true
  end
end
