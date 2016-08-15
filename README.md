# min_sinatra
Simulate sinatra

Example :
<pre>
require './min_sinatra'

get '/' do
  redirect '/index.html'
end

post '/app' do
  session['uname'] = params['uname']
  p session['uname']
  redirect '/start'
end

get '/start' do
  "Welcome" + session['uname']
end

get /re/ do
  [200,{},["hello"]]
end

</pre>

Supports : Regexp route; restful interface; Rack::Session; params; response like Rack as [200,{},["hello"]]

Usage : Simple Web Server.Can use as Single Page Application's Server
