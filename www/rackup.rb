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
    parts = env['PATH_INFO'][1..-1].split('/')
    parts << 'home' if parts.size == 0
    
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

    if File.exists? File.join(File.dirname(__FILE__), 'controllers', parts[0] + '.rb')
      require File.join(File.dirname(__FILE__), 'controllers', parts[0] + '.rb')
      controller = Class.const_get(parts[0].capitalize + 'Controller').new
      
      action = parts[2] || (parts.size == 1 ? 'main' : 'show')
      if controller.respond_to? "do_#{action}"
        controller.template = File.read(Mustache.template_path + "/#{parts[0]}/#{action}.mustache")
        controller.__send__ "do_#{action}", env, parts[1..-1]
        layout = Layout.new controller
        [200, {'Content-Type' => 'text/html'}, layout.render]
      else
        [404, {'Content-Type' => 'text/plain'}, "404: Page not found."]
      end
      
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
