Spree::User.class_eval do
  has_one :subscription, class_name: 'Spree::Subscriber'
  after_create :subscribe_after_create

  private

  def subscribe_after_create
    if receive_emails_agree
      Spree::Subscriber.where(user: self).first_or_create(
        user: self,
        email: email,
        first_name: (!first_name.blank? ? first_name : ''),
        last_name: (!last_name.blank? ? last_name : ''),
        source: 'Registration',
        status: 1
      )
    end
  end
end
