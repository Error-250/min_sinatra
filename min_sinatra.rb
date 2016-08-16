=begin
  Web Frame Work
=end
require 'rack'
require 'json'

module Min_Sinatra
  #
  # set Module instance
  #   * settings - settings for web server
  #     -> route   - all route sets from user
  #     -> port    - set port for server 
  #     -> static  - set static floder
  #     -> json    - set whether retrun json data
  #     -> uses    - all Rack Middleware
  #     -> session - set use session
  #
  class << self
    attr_accessor :settings
  end
  self.settings = {
    :port => 8080,
    :static => 'static',
    :json => false,
    :uses => [],
    :session => false,
    :route => {:get =>[],:post=>[],:put=>[],:delete=>[]}
  }
  #
  # Rack App
  #
  class App
    class << self
      attr_accessor :params
      attr_accessor :env
    end
    self.env = {}
    #
    # function not_found
    #
    def not_found
      [200,{},["<h1>404 Not Found</h1>"]]
    end
    #
    # get Settings
    #
    def settings
      self.class.settings
    end
    #
    # get Settings
    #
    def self.settings
      Min_Sinatra.settings
    end
    #
    # Rack app call function interface
    #
    def call env
      raw = nil
      self.class.env = env
      #
      # match route
      # support : String, Regexp
      # rel - nil| body| [status,{header},[bodys]]
      #
      req = Rack::Request.new env
      self.class.params = req.params
      method = env["REQUEST_METHOD"].downcase
      settings[:route][method.to_sym].each do |p|
        case p[:path]
        when String
          if env["REQUEST_PATH"] == p[:path]
            raw = p[:proc].call
          end
        when Regexp
          if env["REQUEST_PATH"] =~ p[:path]
            if !p[:extend_key].nil? # analize extend_params like /hehe/:id
              req.params[p[:extend_key].to_sym] = $1
            end
            raw = p[:proc].call
          end
        else
          throw :illegal_route
        end
      end
      #
      # anaylize raw
      # nil   - return not_found
      # Array - return raw if match [fixnum, hash, array]
      # other - return [200, {}, [other.to_s]]
      #
      status = 200
      header = {}
      bodys = ""
      if raw.nil?
        not_found
      else
        bodys = raw
        if Array === raw
          status = raw[0]
          header = raw[1]
          bodys = raw[2]
        end
        if settings[:json] == true
          bodys = bodys.to_json
        end
        if Array === bodys
          bodys = bodys.map{|e| e.to_s}
          [status, header, bodys]
        else
          [status, header, [bodys.to_s]]
        end
      end
    end
    #
    # Session
    #
    def self.session
      env["rack.session"]
    end
    #
    # start server
    #
    def self.start
      statics = Rack::File.new settings[:static]
      begin
        wfwapp = Rack::Builder.new do
          if Min_Sinatra.settings[:session] == true
            use Rack::Session::Cookie, :secret => Time.new.to_s, :expire_after => 12
          end
          # Load Rack Middleware
          Min_Sinatra.settings[:uses].each do |mid|
            if mid[:middleware].size > 1
              use mid[:middleware][0], *mid[:middleware][1,mid[:middleware].size]
            else
              use mid[:middleware][0]
            end
          end
          run Rack::Cascade.new [statics, Min_Sinatra::App.new]
        end
        Rack::Handler::WEBrick.run wfwapp, :Port => Min_Sinatra.settings[:port]
      rescue Exception => e
      ensure
        Rack::Handler::WEBrick.shutdown
      end
    end
    #
    # redirect to uri
    #
    def self.redirect uri
      targetURI = nil
      if uri =~ /http:\/\//
        targetURI = uri
      else
        targetURI = "http://" + env["SERVER_NAME"] + ":" + env["SERVER_PORT"] + uri
      end
      [302,{"Location"=> targetURI},[]]
    end
    #
    # set
    #
    def self.set *arg
      settings[arg[0]] = arg[1]
    end
    #
    # use Rack Middleware
    #
    def self.use *arg
      if arg[0] == Rack::Session::Cookie
        set :session, true
      else
        settings[:uses] << { :middleware => arg }
      end
    end
  end
  #
  # function register
  #
  def self.register *methods
    methods.each do | method_name |
      define_method(method_name) do | *path, &block |
        return (Min_Sinatra::App.send method_name, *path, &block) if Min_Sinatra::App.respond_to? method_name
        throw :syntax_error if path[0].nil? or block.nil?
        throw :illegal_route if !(String===path[0]) and !(Regexp === path[0])
        # translate route like /hehe/:id to /^\/hehe\/(.*)$/
        if String === path[0] and path[0] =~ /(:[a-z]*)$/
          extend_key = $1
          path[0] = path[0].delete extend_key
          path[0] = "^" + path[0] + "(.*)$"
          path[0] = Regexp.new path[0]
          extend_key = extend_key.delete ":"
        end
        Min_Sinatra.settings[:route][method_name] << {:path => path[0], :extend_key => extend_key, :proc => block}
      end
    end
  end
  register :get, :post, :put, :delete, :set, :params, :redirect, :session, :use
  
  at_exit { Min_Sinatra::App.start if $!.nil? || $!.is_a?(SystemExit) && $!.success?}
end
extend Min_Sinatra