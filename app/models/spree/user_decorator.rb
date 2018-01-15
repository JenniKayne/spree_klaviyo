Spree::User.class_eval do
  has_one :subscription
  after_update :update_subscription

  def subscribed?
    !subscription.nil? && subscription.subscribed?
  end

  def subscription_firstname
    try(:firstname).to_s
  end

  def subscription_lastname
    try(:lastname).to_s
  end

  def update_subscription
    return unless subscribed?
    subscription.update(email: email) if saved_change_to_email?

    if defined?(firstname) && saved_change_to_firstname? ||
        defined?(lastname) && saved_change_to_lastname? ||
        saved_change_to_email?
      subscription.set_as_updated
    end
  end
end
