# Configure Rails Environment
ENV['RAILS_ENV'] = 'test'

# Uncomment this to mock the requests.
=begin
require 'webmock/rspec'
require 'support/fake_klaviyo'
WebMock.disable_net_connect!(allow_localhost: true)
=end

RSpec.configure do |config|

  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec
  config.color = true

  config.before(:each) do
    # stub_request(:any, /a.klaviyo.com/).to_rack(FakeKlaviyo)
  end
end
