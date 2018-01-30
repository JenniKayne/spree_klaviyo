Spree::User.class_eval do
  has_one :subscription
  after_update :update_subscription

  after_create :synchronize_subscription_with_receive_emails_agree
  after_update :synchronize_subscription_with_receive_emails_agree

  def subscribed?
    !subscription.nil? && subscription.subscribed?
  end

  def synchronize_subscription_with_receive_emails_agree(source = 'Registration')
    if receive_emails_agree && subscription.nil?
      Spree::Subscription.where(user: self).first_or_create(
        user: self, email: email, source: source
      )
    elsif receive_emails_agree && !subscribed?
      subscription.subscribe
    elsif !receive_emails_agree && subscribed?
      subscription.unsubscribe
    end
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
