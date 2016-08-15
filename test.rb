require './min_sinatra'

json_format

get '/' do
  redirect '/index.html'
end

post '/app' do
  session['uname'] = params['uname']
  p session['uname']
  redirect '/start'
end

get '/start' do
  {"Welcome" => session['uname']}
end

get /re/ do
  [200,{},[{"say" => "hello"}]]
end

