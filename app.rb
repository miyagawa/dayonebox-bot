require 'sinatra'
require 'json'

post '/callback' do
  response.body = JSON.dump({ :body => "" })
end
