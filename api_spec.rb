ENV['RACK_ENV'] = 'test'

require 'rspec'
require 'rack/test'

require_relative 'api'

describe 'API' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  before do
    delete '/visitors'
  end

  it 'can create, list, and delete visitors' do
    password = 'mypass'
    post '/visitors', {password: password}
    get '/visitors'
    expect(last_response).to be_ok

    response_body = JSON.parse(last_response.body)
    expect(response_body.length).to be(1)

    visitor = response_body[0]
    expect(visitor).to include({'password' => password})

    delete "/visitors/#{visitor['id']}"
    get '/visitors'
    expect(last_response).to be_ok
    expect(JSON.parse(last_response.body).length).to be(0)
  end
end
