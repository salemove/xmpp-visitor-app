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

  after do
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

  it 'can create and list valid cat pictures' do
    password = "apass"
    url = 'https://cdn.cats.io/cute_cat.jpeg'

    post '/visitors', {password: password}
    get '/visitors'
    visitor = JSON.parse(last_response.body)[0]

    basic_authorize visitor['id'], password
    post '/cat_pics', {url: url}
    expect(last_response).to be_ok

    get '/cat_pics'
    expect(last_response).to be_ok
    response_body = JSON.parse(last_response.body)
    expect(response_body.length).to be(1)
    expect(response_body[0]).to include({
      "visitor_id" => visitor['id'],
      "cat_pic_url" => url,
      "valid" => true
    })
  end

  it 'can create and list invalid cat pictures' do
    password = "apass"
    url = 'https://cdn.cats.io/a_random_cat.jpeg'

    post '/visitors', {password: password}
    get '/visitors'
    visitor = JSON.parse(last_response.body)[0]

    basic_authorize visitor['id'], password
    post '/cat_pics', {url: url}
    expect(last_response).not_to be_ok
    expect(last_response.status).to eql(422)
    response_body = JSON.parse(last_response.body)
    expect(response_body['debug_message']).to match(/cobrowse\.sh/)
    expect(response_body).to include({"message" => "Cat pictures have to be cute!"})

    get '/cat_pics'
    expect(last_response).to be_ok
    response_body = JSON.parse(last_response.body)
    expect(response_body.length).to be(1)
    expect(response_body[0]).to include({
      "visitor_id" => visitor['id'],
      "cat_pic_url" => url,
      "valid" => false
    })
  end

  it 'rejects cat pics if not auhtorized' do
    post '/cat_pics', {url: 'https://cdn.cats.io/a_random_cat.jpeg'}
    expect(last_response).not_to be_ok
    expect(last_response.status).to eql(401)
  end
end
