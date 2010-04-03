require File.join(File.dirname(__FILE__), '..', 'common', 'client')
require File.join(File.dirname(__FILE__), '..', 'common', 'models')

require 'cgi'
require 'time'

require 'rubygems'
require 'json'
require 'mustache'

Mustache.template_path = File.dirname(__FILE__) + '/views'

$www_fbi = FBI::Client.new 'www-' + rand.to_s, 'hil0l'
$www_fbi.connect
      
class HTTPError < StandardError; def code; 500; end; end
class FileNotFound < HTTPError; def code; 404; end; end
class Redirect < HTTPError; def code; 302; end; end
class TempRedirect < Redirect; def code; 302; end; end
class PermRedirect < Redirect; def code; 301; end; end
class PermissionDenied < HTTPError; def code; 403; end; end
class ServersideError < HTTPError; def code; 500; end; end

Rackup = Rack::Builder.new do
  fbi = $www_fbi
  
  use Rack::Reloader, 0
  use Rack::ContentLength
  app = proc do |env|
    
    begin
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
      
      
      # This is a hackity hack.
      parts = env['PATH_INFO'][1..-1].split('/')
      if parts.any? && File.exists?(File.join(File.dirname(__FILE__), 'webhooks', parts[0] + '.rb'))
        require File.join(File.dirname(__FILE__), 'webhooks', parts[0] + '.rb')
        Class.const_get(parts[0].capitalize + 'Hook').new.run env, fbi
        return [200, {'Content-Type' => 'text/plain'}, "Hook processed."]
      end
      
      
      route = routing.find env['PATH_INFO']
      raise FileNotFound unless route
      
      $headers = {'Content-Type' => 'text/html'}
      
      env[:session] = UserSession.load env
      env[:user] = env[:session] && env[:session].user
      
      return [200, $headers, route.handle(env['PATH_INFO'], env)]
      
    #~ rescue FileNotFound => ex
      #~ return [ex.code, {'Content-Type' => 'text/plain'}, "404: Page not found."]
    rescue Redirect => ex
      path = "#{env['rack.url_scheme']}://#{env['HTTP_HOST']}#{ex.message}"
      return [ex.code, {'Content-Type' => 'text/plain', 'Location' => path}, "You are being redirected to #{path}"]
    rescue HTTPError => ex
      return [ex.code, {'Content-Type' => 'text/plain'}, ex.inspect]
      
    rescue => ex
      puts ex, ex.message, ex.backtrace
      return [500, {'Content-Type' => 'text/plain'}, ex.inspect + "\n" + ex.message + "\n" + ex.backtrace.join("\n")]
    end
  end
  run app
end.to_app
