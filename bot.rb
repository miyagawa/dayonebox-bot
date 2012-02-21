#!/usr/bin/env ruby
require 'xmpp4r-simple'
require 'eventmachine'
require 'em-http-request'
require 'json'
require './monkey'

Jabber::debug = true

im = Jabber::Simple.new(ENV['JABBER_USER'], ENV['JABBER_PASSWORD'])
im.accept_subscriptions = true

uri = ENV['CALLBACK_URL'] || 'http://0.0.0.0:5000/callback'

EM.run do
  EM::PeriodicTimer.new(1) do
    im.received_messages do |msg|
      params = { :body => msg.body, :from => msg.from }
      http = EM::HttpRequest.new(uri).post :body => params
      http.callback do
        begin
          data = JSON.parse http.response
          im.deliver msg.from, data['body']
        rescue JSON::ParseError
          im.deliver msg.from, 'Error happened'
        end
      end
      http.errback do
        im.deliver msg.from, 'Error happened'
      end
    end
  end
end
