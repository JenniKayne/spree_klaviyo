module Spree
  class Subscription < ActiveRecord::Base
    belongs_to :user
    validates :email, presence: true, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i }
    after_create :schedule_synchronization

    STATE_SUBSCRIBED_NOT_SYNCED = 'new'
    STATE_SUBSCRIBED_SYNCED = 'subscribed'
    STATE_UNSUBSCRIBED_NOT_SYNCED = 'unsubscribed_new'
    STATE_UNSUBSCRIBED_SYNCED = 'unsubscribed'
    STATE_UPDATED = 'updated'

    STATES_SUBSCRIBED = [
      STATE_SUBSCRIBED_NOT_SYNCED,
      STATE_SUBSCRIBED_SYNCED,
      STATE_UPDATED
    ]

    STATES_UNSUBSCRIBED = [
      STATE_UNSUBSCRIBED_NOT_SYNCED,
      STATE_UNSUBSCRIBED_SYNCED
    ]

    STATES_SYNCED = [
      STATE_SUBSCRIBED_SYNCED,
      STATE_UNSUBSCRIBED_SYNCED
    ]

    STATES_NOT_SYNCED = [
      STATE_SUBSCRIBED_NOT_SYNCED,
      STATE_UNSUBSCRIBED_NOT_SYNCED
    ]

    scope :not_synced, -> { where(state: STATES_NOT_SYNCED) }
    scope :synced, -> { where(state: STATES_SYNCED) }

    def klaviyo_body
      request_body = {
        email: email
      }

      request_body[:first_name] = user.subscription_firstname unless user&.subscription_firstname.blank?
      request_body[:last_name] = user.subscription_lastname unless user&.subscription_lastname.blank?
      request_body[:source] = source unless source.blank?

      request_body
    end

    def schedule_synchronization
      SpreeKlaviyo::UpdateSubscriptionStatusJob.perform_later(self)
    end

    def set_as_synced
      if subscribed?
        update(state: STATE_SUBSCRIBED_SYNCED)
      else
        update(state: STATE_UNSUBSCRIBED_SYNCED)
      end
    end

    def set_as_updated
      update(state: STATE_UPDATED)
      schedule_synchronization
    end

    def subscribe
      unless subscribed?
        update(state: STATE_SUBSCRIBED_NOT_SYNCED)
        schedule_synchronization
      end
    end

    def subscribed?
      STATES_SUBSCRIBED.include?(state)
    end

    def synced?
      STATES_SYNCED.include?(state)
    end

    def updated?
      state == STATE_UPDATED
    end

    def unsubscribe
      if subscribed?
        update(state: STATE_UNSUBSCRIBED_NOT_SYNCED)
        schedule_synchronization
      end
    end

    def unsubscribed?
      STATES_UNSUBSCRIBED.include?(state)
    end
  end
end
