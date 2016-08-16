require '../min_sinatra'

use Rack::Session::Cookie, :secret => Time.now.to_s, :expire_after => 12

get '/' do
  redirect '/index.html'
end

post '/app' do
  session['uname'] = params['uname']
  p session['uname']
  redirect '/start'
end

get '/hehe/:id' do
  params[:id]
end

get '/start' do
  {"Welcome" => session['uname']}
end

get /re/ do
  [200,{},[{"say" => "hello"}]]
end

