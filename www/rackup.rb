require File.join(File.dirname(__FILE__), '..', 'common', 'client')
require 'cgi'
require 'time'

require 'rubygems'
require 'json'
require 'mustache'

Mustache.template_path = File.dirname(__FILE__) + '/views'

$www_fbi = FBI::Client.new 'www', 'hil0l'
$www_fbi.connect

# Hacky hacky hacky...
$fbi_sock = TCPSocket.new 'localhost', 5348
$fbi_sock.puts({:action => 'auth', :user => 'www_worker-' + rand.to_s, :secret => 'hil0l'}.to_json)
2.times { $fbi_sock.gets }

Rackup = Rack::Builder.new do
  fbi = $www_fbi
  
  use Rack::Reloader, 0
  use Rack::ContentLength
  app = proc do |env|
  
    class Layout < Mustache
      self.template_path = File.dirname(__FILE__) + '/views'
      
      def initialize target
        @target = target
      end
      
      def yield
        @target
      end
    end
    
    require 'lib/routing'
    require 'lib/renderer'
    require 'lib/controller'
    require 'lib/model'

    require 'models/project'
    require 'models/repo'
    require 'models/commit'
    require 'models/user'
    require 'models/user_session'
    require 'models/project_member'
    require 'models/service'
    
    parts = env['PATH_INFO'][1..-1].split('/')
    
    routing = Routing.new
    
    routing.setup do
      connect '/?$', 'home', 'index'
      
      connect '/projects/?$', 'projects', 'main'
      connect '/projects/new$', 'projects', 'new'
      connect '/projects/([^/]+)/?$', 'projects', 'show'
      connect '/projects/([^/]+)/edit$', 'projects', 'edit'
      
      connect '/projects/([^/]+)/members/add$', 'projects', 'add_member'
      connect '/projects/([^/]+)/members/join$', 'projects', 'join'
      
      sub_route '/projects/([^/]+)/repos' do
        connect '/?$', 'repos', 'list'
        connect '/new$', 'repos', 'new'
        connect '/([^/]+)/?$', 'repos', 'show'
        connect '/([^/]+)/edit$', 'repos', 'edit'
        connect '/([^/]+)/tree/(.*)$', 'repos', 'tree'
        connect '/([^/]+)/blob/(.+)$', 'repos', 'blob'
      end
      
      sub_route '/projects/([^/]+)/commits' do
        connect '/?$', 'commits', 'list', :mode => 'project'
        connect '/authors/([^/]+)/?$', 'commits', 'list', :mode => 'author'
        connect '/repos/([^/]+)/?$', 'commits', 'list', :mode => 'repo'
      end
      
      sub_route '/projects/([^/]+)/wiki' do
        connect '/?$', 'wiki', 'index'
        connect '/show/([^/]+)$', 'wiki', 'show'
        connect '/new/?', 'wiki', 'new'
        connect '/edit/([^/]+)$', 'wiki', 'edit'
        connect '/save/([^/]+)$', 'wiki', 'save'
        connect '/history/([^/]+)$', 'wiki', 'history'
        connect '/commits/([^/]+)$', 'wiki', 'commits'
      end
      
      sub_route '/users' do
        connect '/?$', 'users', 'list'
        connect '/([^/]+)/?$', 'users', 'show'
      end
      
      sub_route '/account' do
        connect '/?$', 'users', 'show', :self => true
        connect '/new$', 'account', 'new'
        connect '/edit$', 'account', 'edit'
        connect '/save$', 'account', 'save'
      end
      
      sub_route '/services' do
        connect '/?$', 'services', 'list'
        connect '/new$', 'services', 'new'
        connect '/([^/]+)/?$', 'services', 'show'
        connect '/([^/]+)/edit$', 'services', 'edit'
      end
      
      connect '/login$', 'account', 'login'
      connect '/logout$', 'account', 'logout'
    end
    
    route = routing.find env['PATH_INFO']
    if route
      $headers = {'Content-Type' => 'text/html'}
      
      env[:session] = UserSession.load env
      #puts env[:session].inspect[0, 100]
      env[:user] = env[:session] && env[:session].user
      
      [200, $headers, route.handle(env['PATH_INFO'], env)]
    #~ else
      #~ [404, {'Content-Type' => 'text/plain'}, "404: Page not found."]
    #~ end
      
    elsif File.exists? File.join(File.dirname(__FILE__), 'webhooks', parts[0] + '.rb')
      require File.join(File.dirname(__FILE__), 'webhooks', parts[0] + '.rb')
      Class.const_get(parts[0].capitalize + 'Hook').new.run env, fbi
      [200, {'Content-Type' => 'text/plain'}, "Hook processed."]
      
    else
      [404, {'Content-Type' => 'text/plain'}, "404: Page not found."]
    end
  end
  run app
end.to_app
