require 'sinatra'
require 'json'
require 'dropbox_sdk'
require 'uuidtools'
require 'cgi'

use Rack::CommonLogger
use Rack::Session::Cookie

db = {}

post '/callback' do
  sess = db[params[:from]]
  if sess
    uuid = SecureRandom.uuid().gsub(/-/, '').upcase
    file = create_file(params[:body], uuid)
    sess.put_file("/Journal.dayone/entries/#{uuid}.doentry", file)
    body = "Created a new entry!"
  else
    body = "Your account hasn't been setup: " +
           "Go to #{url("/auth?from=#{params[:from]}")} and authorize this app."
  end
  JSON.dump({ :body => body })
end

def create_file(body, uuid)
  <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
<key>Creation Date</key>
<date>#{Time.now.utc.strftime "%Y-%m-%dT%H:%M:%SZ"}</date>
<key>Entry Text</key>
<string>#{CGI::escapeHTML(body)}</string>
<key>Starred</key>
<false/>
<key>UUID</key>
<string>#{uuid}</string>
</dict>
</plist>
EOF
end

get '/auth' do
  sess = DropboxSession.new(ENV['DROPBOX_KEY'], ENV['DROPBOX_SECRET'])
  sess.get_request_token
  session[:dropbox] = sess.serialize
  session[:from] = params[:from]
  redirect sess.get_authorize_url(url '/auth/callback')
end

get '/auth/callback' do
  sess = DropboxSession.deserialize(session[:dropbox])
  sess.get_access_token
  db[session[:from]] = DropboxClient.new(sess, :dropbox)
end
