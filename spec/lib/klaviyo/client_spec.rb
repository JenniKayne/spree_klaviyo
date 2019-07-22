require 'spec_helper'
require 'klaviyo/client'

describe Klaviyo::Client do
  let(:client) { Klaviyo::Client.new('pk_f6873a3cbcee7ebbd7a47ae66905c02745') }
  let(:list_id) { 'JdsSXy' }
  let(:email) { 'jenni@example.com' }

  after(:each) do
    client.unsubscribe(list_id, email)
  end

  context 'when interacting with memberships ' do
    describe '#add_to_list' do
      it 'adds email to the list' do
        client.add_to_list(list_id, [{ email: email }])

        expect(
          client.email_on_the_list?(list_id, email)
        ).to be_truthy
      end
    end

    describe '#email_on_the_list' do
      it 'checks with an email on the list' do
        client.add_to_list(list_id, [{ email: email }])

        expect(
          client.email_on_the_list?(list_id, email)
        ).to be_truthy
      end

      it 'checks with an off list e-mail' do
        expect(
          client.email_on_the_list?(list_id, email)
        ).to be_falsy
      end
    end

    describe '#fetch_list_member' do
      it 'fetchs an existent profile' do
        client.add_to_list(list_id, [{ email: email }])

        member = client.fetch_list_member(list_id, email)
        expect(member['email']).to eq(email)
      end

      it 'fetchs an inexistent profile' do
        member = client.fetch_list_member(list_id, 'inexistent@example.com')
        expect(member).to be_nil
      end
    end

    describe '#remove_from_list' do
      it 'adds and remove an email to the list' do
        client.add_to_list(list_id, [{ email: email }])

        expect(
          client.email_on_the_list?(list_id, email)
        ).to be_truthy

        client.remove_from_list(list_id, email)

        expect(
          client.email_on_the_list?(list_id, email)
        ).to be_falsy
      end
    end
  end
end
