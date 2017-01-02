module Spree
  module Api
    class NewsletterController < Spree::Api::BaseController
      SUBSCRIPTION_SOURCES = ['Footer', 'Header', 'Modal'].freeze

      def create
        user_email = params['email']
        user_source = !params['source'].nil? && SUBSCRIPTION_SOURCES.include?(params['source']) ? params['source'] : 'Footer'

        if user_email.nil? || (user_email =~ /\A([\w+\-]\.?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i).nil?
          render json: { result: :error, msg: 'Please enter a valid email address' }
          return
        end

        user_id = current_spree_user.nil? ? nil : current_spree_user.id
        if !user_id.nil? && current_spree_user.email != user_email
          user_id = nil
        end

        subscriber = Spree::Subscriber.where(email: user_email, user_id: user_id).first
        if subscriber.nil?
          subscriber = Spree::Subscriber.new(
            user_id: user_id,
            email: user_email,
            source: user_source
          )
          result = subscriber.subscribe! true
          if result
            render json: { result: :success }
          else
            render json: { result: :error, msg: 'Please try again in 5 minutes.' }
          end
        elsif subscriber.subscribed?
          render json: { result: :error, msg: 'This email is already subscribed.' }
        else
          subscriber.source = 'Footer'
          result = subscriber.subscribe! true
          current_spree_user.receive_emails_agree = true
          current_spree_user.save
          if result
            render json: { result: :success }
          else
            render json: { result: :error, msg: 'Please try again in 5 minutes.' }
          end
        end
      end
    end
  end
end
