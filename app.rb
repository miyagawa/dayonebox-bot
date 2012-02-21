require 'sinatra'
require 'json'

use Rack::CommonLogger

post '/callback' do
  response.body = JSON.dump({ :body => "You said #{params[:body]}" })
end
