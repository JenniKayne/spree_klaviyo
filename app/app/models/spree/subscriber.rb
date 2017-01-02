module Spree
  class Subscriber < ActiveRecord::Base
    belongs_to :user
    validates :email, presence: true, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i }

    scope :not_synced, -> { where('status = ? OR status = ?', 1, 3) }
    scope :synced, -> { where('status = ? OR status = ?', 2, 4) }

    # Status:
    # 1 - Subscribed, not synced
    # 2 - Subscribed, synced
    # 3 - Unsubscribed, not synced
    # 4 - Subscribed, synced

    def subscribed?
      status == 1 || status == 2
    end

    def subscribe(state)
      if state
        if !subscribed?
          self.status = 1
        end
      elsif subscribed?
        self.status = 3
      end
    end

    def subscribe!(state)
      subscribe state
      save
    end

    def synced!
      if status == 1
        self.status = 2
      elsif status == 3
        self.status = 4
      end
      save
    end

    def synced?
      status == 1 || status == 3
    end

    def unsubscribe!
      subscribe! false
    end
  end
end
