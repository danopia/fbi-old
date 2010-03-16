require File.join(File.dirname(__FILE__), '..', 'common', 'client')
require 'cgi'
require 'time'

require 'rubygems'
require 'sequel'
require 'json'
require 'mustache'

DB = Sequel.sqlite('www.db')
Commits = DB[:commits]
Repos = DB[:repos]
Projects = DB[:projects]
Pages = DB[:pages]

Mustache.template_path = File.dirname(__FILE__) + '/views'

$www_fbi = FBI::Client.new 'www', 'hil0l'
EventMachine.next_tick { $www_fbi.connect }

Rackup = Rack::Builder.new do
  fbi = $www_fbi
  
  use Rack::Reloader, 0
  use Rack::ContentLength
  app = proc do |env|
  
    require 'models/project'
    require 'models/repo'
    require 'models/commit'
    require 'models/page'
    
    class Layout < Mustache
      self.template_path = File.dirname(__FILE__) + '/views'
      
      def initialize target
        @target = target
      end
      
      def yield
        @target.render
      end
    end
    
    parts = env['PATH_INFO'][1..-1].split('/')
    
    require 'lib/routing'
    
    routing = Routing.new
    
    routing.setup do
      connect /^\/projects\/?$/, 'projects', 'main'
      connect /^\/projects\/([^\/]+)\/?$/, 'projects', 'show'
      
      connect /^\/projects\/([^\/]+)\/repos\/?$/, 'repos', 'list'
      connect /^\/projects\/([^\/]+)\/repos\/([^\/]+)\/?$/, 'repos', 'tree'
      connect /^\/projects\/([^\/]+)\/repos\/([^\/]+)\/tree\/(.*)$/, 'repos', 'tree'
      connect /^\/projects\/([^\/]+)\/repos\/([^\/]+)\/blob\/(.+)$/, 'repos', 'blob'
      
      connect /^\/projects\/([^\/]+)\/commits\/?$/, 'commits', 'list', :mode => 'project'
      connect /^\/projects\/([^\/]+)\/commits\/authors\/([^\/]+)\/?$/, 'commits', 'list', :mode => 'author'
      connect /^\/projects\/([^\/]+)\/commits\/repos\/([^\/]+)\/?$/, 'commits', 'list', :mode => 'repo'
      
      connect /^\/projects\/([^\/]+)\/wiki\/?$/, 'wiki', 'index'
      connect /^\/projects\/([^\/]+)\/wiki\/show\/([^\/]+)$/, 'wiki', 'show'
      connect /^\/projects\/([^\/]+)\/wiki\/edit\/([^\/]+)$/, 'wiki', 'edit'
      connect /^\/projects\/([^\/]+)\/wiki\/save\/([^\/]+)$/, 'wiki', 'save'
      connect /^\/projects\/([^\/]+)\/wiki\/history\/([^\/]+)$/, 'wiki', 'history'
      connect /^\/projects\/([^\/]+)\/wiki\/commits\/([^\/]+)$/, 'wiki', 'commits'
    end
    
    route = routing.find env['PATH_INFO']
    if route
      [200, {'Content-Type' => 'text/html'}, route.handle(env['PATH_INFO'], env)]
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
