require 'sinatra/base'

class FakeKlaviyo < Sinatra::Base
  get '/api/v2/list/:list_id/members' do
    json_response 200, params['emails'], 'fetch_member_from_list.json'
  end

  post '/api/v2/list/:list_id/members' do
    json_response 200, 'invalid.json', 'add_member_to_list.json'
  end

  private

  def json_response(response_code, file_name, default_file)
    content_type :json
    status response_code

    json_file = File.dirname(__FILE__) + '/../fixtures/klaviyo/' + file_name, 'rb'

    if File.exists?(json_file)
      File.open(json_file, 'rb').read
    else
      File.open(File.dirname(__FILE__) + '/../fixtures/klaviyo/default-' + default_file, 'rb').read
    end
  end
end
