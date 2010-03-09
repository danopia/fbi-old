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

Rackup = Rack::Builder.new do
  use Rack::Reloader, 0
  use Rack::ContentLength
  app = proc do |env|
    parts = env['PATH_INFO'][1..-1].split('/')
    parts << 'home' if parts.size == 0
    
    require 'models/project'
    require 'models/repo'
    require 'models/commit'
    require 'models/page'
    
    class Mustache
      class Template
        def compile_sections(src)
          res = ""
          while src =~ /#{otag}\#([^\}]*)#{ctag}\s*(.+?)#{otag}\/\1#{ctag}\s*/m
            # $` = The string to the left of the last successful match
            res << compile_tags($`)
            name = $1.strip.to_sym.inspect
            code = compile($2)
            ctxtmp = "ctx#{tmpid}"
            res << ev(<<-compiled)
            if v = ctx[#{name}]
              v = [v] if !v.is_a?(Array) # shortcut when passed a single object
              v.map { |h| ctx.push(h); c = #{code}; ctx.pop; c }.join
            end
            compiled
            # $' = The string to the right of the last successful match
            src = $'
          end
          res << compile_tags(src)
        end
      end
      
      class Context
        def initialize(mustache)
          @stack = [mustache]
        end
        
        def push new
          @stack.unshift new
        end
        def pop
          @stack.shift
        end
        
        def [] name
          responder = @stack.find {|item| item.respond_to?(name) }
          if responder
            responder.__send__ name
          elsif @stack.last.raise_on_context_miss?
            raise ContextMiss.new("Can't find #{name} in #{@stack.inspect}")
          else
            nil
          end
        end
      end
    end
    
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
      
      #parts << 'home' if parts.size == 1
      action = parts[2] || (parts.size == 1 ? 'main' : 'show')
      if controller.respond_to? "do_#{action}"
        controller.template = File.read(Mustache.template_path + "/#{parts[0]}/#{action}.mustache")
        controller.__send__ "do_#{action}", env, parts[1..-1]
        puts controller.template.compile
        #p eval(controller.template.compile)
        layout = Layout.new controller
        [200, {'Content-Type' => 'text/html'}, layout.render]
      else
        [404, {'Content-Type' => 'text/plain'}, "404: Page not found."]
      end
      
    elsif File.exists? File.join(File.dirname(__FILE__), 'webhooks', parts[0] + '.rb')
      require File.join(File.dirname(__FILE__), 'webhooks', parts[0] + '.rb')
      Class.const_get(parts[0].capitalize + 'Hook').new.run env
      [200, {'Content-Type' => 'text/plain'}, "Hook processed."]
      
    else
      [404, {'Content-Type' => 'text/plain'}, "404: Page not found."]
    end
  end
  run app
end.to_app

EM.next_tick do
  FBI::Client.connect 'thin', 'hil0l'
end
