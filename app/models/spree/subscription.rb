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

    def custom_merge_fields
      {}
    end

    def email_md5
      Digest::MD5.hexdigest email.downcase
    end

    def mailchimp_request_body
      status = if Rails.application.secrets.mailchimp_opt_in_enabled
                 state == STATE_SUBSCRIBED_NOT_SYNCED ? 'pending' : 'subscribed'
               else
                 'subscribed'
               end

      request_body = {
        email_address: email,
        status: status,
        double_optin: false,
        update_existing: true
      }
      merge_fields = {
        FNAME: (user.subscription_firstname unless user.nil? || user.subscription_firstname.blank?),
        LNAME: (user.subscription_lastname unless user.nil? || user.subscription_lastname.blank?),
        SOURCE: (source unless source.blank?)
      }.merge!(custom_merge_fields).compact
      request_body[:merge_fields] = merge_fields unless merge_fields.blank?
      request_body
    end

    def schedule_synchronization
      SpreeMailchimp::UpdateSubscriptionStatusJob.perform_later(self)
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
      STATES_SUBSCRIBED.include? state
    end

    def synced?
      STATES_SYNCED.include? state
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
      STATES_UNSUBSCRIBED.include? state
    end
  end
end
