module Spree
  module Api
    class NewsletterController < Spree::Api::BaseController
      SUBSCRIPTION_SOURCES = ['Footer', 'Header', 'Modal', 'Registration', 'Homepage', 'Account'].freeze

      def delete
        current_spree_user.subscription.unsubscribe if current_spree_user.present? && current_spree_user.subscribed?
        render json: { success: true }
      end

      def create
        if email.nil? || (email =~ /\A([\w+\-]\.?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i).nil?
          render json: { success: false, message: 'Please enter a valid email address' }
          return
        end

        subscription = Spree::Subscription.where(email: email, user_id: user_id).first
        if subscription.nil?
          # Subscribe
          subscription = Spree::Subscription.new(user_id: user_id, email: email, source: source)
          if subscription.save
            handle_custom_fields(subscription)
            render json: { success: true, message: 'Thank you!' }
          else
            render json: { success: false, message: 'Please try again in 5 minutes.' }
          end
        elsif subscription.subscribed?
          # Already subscribed
          render json: { success: false, message: 'This email is already subscribed.' }
        else
          # Resubscribe if unsubscribed
          subscription.subscribe
          handle_custom_fields(subscription)
          render json: { success: true }
        end
      end

      private

      def custom_subsciption_sources
        []
      end

      def email
        params['email'] || current_spree_user.email
      end

      def handle_custom_fields(subscription)
      end

      def source
        !params['source'].nil? &&
          (SUBSCRIPTION_SOURCES + custom_subsciption_sources).include?(params['source']) ? params['source'] : ''
      end

      def user_id
        if current_spree_user.present? && current_spree_user.email == email
          current_spree_user.id
        end
      end
    end
  end
end
