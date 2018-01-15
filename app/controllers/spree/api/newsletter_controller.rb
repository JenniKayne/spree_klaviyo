module Spree
  module Api
    class NewsletterController < Spree::Api::BaseController
      SUBSCRIPTION_SOURCES = ['Footer', 'Header', 'Modal', 'Registration', 'Homepage', 'Account'].freeze

      def delete
        current_spree_user.subscription.unsubscribe! if current_spree_user
        render json: { result: :success }
      end

      def create
        if email.nil? || (email =~ /\A([\w+\-]\.?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i).nil?
          render json: { result: :error, msg: 'Please enter a valid email address' }
          return
        end

        subscription = Spree::Subscription.where(email: email, user_id: user_id).first
        if subscription.nil?
          # Subscribe
          subscription = Spree::Subscription.new(user_id: user_id, email: email, source: source)
          if subscription.save
            render json: { result: :success }
          else
            render json: { result: :error, msg: 'Please try again in 5 minutes.' }
          end
        elsif subscription.subscribed?
          # Already subscribed
          render json: { result: :error, msg: 'This email is already subscribed.' }
        else
          # Resubscribe if unsubscribed
          subscription.subscribe
          render json: { result: :success }
        end
      end

      private

      def email
        params['email'] || current_spree_user.email
      end

      def source
        !params['source'].nil? && SUBSCRIPTION_SOURCES.include?(params['source']) ? params['source'] : ''
      end

      def user_id
        if current_spree_user.present? && current_spree_user.email == email
          current_spree_user.id
        end
      end
    end
  end
end
