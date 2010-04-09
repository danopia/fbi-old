require File.join(File.dirname(__FILE__), '..', 'common', 'client')
require File.join(File.dirname(__FILE__), '..', 'common', 'models')

require 'cgi'
require 'time'

require 'rubygems'
require 'json'
require 'mustache'

require 'lib/routing'
require 'lib/renderer'
require 'lib/controller'
require 'lib/errors'

Mustache.template_path = File.dirname(__FILE__) + '/views'

$www_fbi = FBI::Client.new 'www-' + rand.to_s, 'hil0l'
$www_fbi.connect

Rackup = Rack::Builder.new do
  use Rack::Reloader, 0
  use Rack::ContentLength
  
  app = proc do |env|
    begin
      env[:fbi] = $www_fbi
      env[:headers] = {'Content-Type' => 'text/html'}
    
      routing = Routing.new do
        connect '/?$', 'home', 'index'
        
        connect '/github$', 'hooks', 'github'
        connect '/bitbucket$', 'hooks', 'bitbucket'
        
        connect '/projects/?$', 'projects', 'main'
        connect '/projects/new$', 'projects', 'new'
        
        sub_route '/projects/([^/]+)' do
          connect '/?$', 'projects', 'show'
          connect '/edit$', 'projects', 'edit'
          
          connect '/members/add$', 'projects', 'add_member'
          connect '/members/join$', 'projects', 'join'
          
          sub_route '/repos' do
            connect '/?$', 'repos', 'list'
            connect '/new$', 'repos', 'new'
            connect '/([^/]+)/?$', 'repos', 'show'
            connect '/([^/]+)/edit$', 'repos', 'edit'
            connect '/([^/]+)/tree/(.*)$', 'repos', 'tree'
            connect '/([^/]+)/blob/(.+)$', 'repos', 'blob'
          end
          
          sub_route '/commits' do
            connect '/?$', 'commits', 'list', :mode => 'project'
            connect '/authors/([^/]+)/?$', 'commits', 'list', :mode => 'author'
            connect '/repos/([^/]+)/?$', 'commits', 'list', :mode => 'repo'
          end
          
          sub_route '/wiki' do
            connect '/?$', 'wiki', 'index'
            connect '/show/([^/]+)$', 'wiki', 'show'
            connect '/new/?', 'wiki', 'new'
            connect '/edit/([^/]+)$', 'wiki', 'edit'
            connect '/save/([^/]+)$', 'wiki', 'save'
            connect '/history/([^/]+)$', 'wiki', 'history'
            connect '/commits/([^/]+)$', 'wiki', 'commits'
          end
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
        
        sub_route '/irc' do
          sub_route '/networks' do
            connect '/?$', 'irc_networks', 'list'
            connect '/new$', 'irc_networks', 'new'
            connect '/([^/]+)/?$', 'irc_networks', 'show'
            connect '/([^/]+)/edit$', 'irc_networks', 'edit'
          
            sub_route '/([^/]+)/channels' do
              connect '/?$', 'irc_channels', 'list'
              connect '/new$', 'irc_channels', 'new', :with => :network
              connect '/([^/]+)/?$', 'irc_channels', 'show'
              connect '/([^/]+)/edit$', 'irc_channels', 'edit'
            end
          end
          
          connect '/channels/new$', 'irc_channels', 'new'
        end
        
        connect '/login$', 'account', 'login'
        connect '/logout$', 'account', 'logout'
      end
      
      route = routing.find env['PATH_INFO']
      raise HTTP::NotFound unless route
      
      env[:session] = UserSession.load env
      env[:user] = env[:session] && env[:session].user
      
      return [200, env[:headers], route.handle(env['PATH_INFO'], env)]
      
    rescue HTTP::Redirect => ex
      path = "#{env['rack.url_scheme']}://#{env['HTTP_HOST']}#{ex.path}"
      env[:headers]['Location'] = path
      return [ex.code, env[:headers], ex.message]
      
    rescue HTTP::Error => ex
      return [ex.code, env[:headers], ex.message]
      
    rescue => ex
      puts ex, ex.message, ex.backtrace
      env[:headers]['Content-Type'] = 'text/plain'
      return [500, env[:headers], ex.inspect + "\n" + ex.message + "\n" + ex.backtrace.join("\n")]
    end
  end
  run app
end.to_app
