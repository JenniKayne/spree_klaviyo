Spree::User.class_eval do
  has_one :subscription, class_name: 'Spree::Subscriber'
end
