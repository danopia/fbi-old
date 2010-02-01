require File.join(File.dirname(__FILE__), '..', 'common', 'client')
require 'cgi'

Hooks = {}

Hooks['/github'] = lambda {|env|
  data = env['rack.input'].read
  data = JSON.parse CGI::unescape(data[8..-1])
  
  # merge floods
  #~ if data['commits'].size > 3
    #~ dropped = data['commits'].size - 3
    #~ data['commits'].shift until data['commits'].size == 3
    #~ data['commits'].first['message'] = "(#{dropped} previous commit[s] dropped --FBI) " + data['commits'].first['message']
  #~ end
  #~ 
  #~ data['commits'].pop if data['commits'].size > 1 && data['commits'].last['message'] =~ /^Merge remote branch/ && data['repository']['fork']
  
  data['commits'].each do |commit|
  
    # previous commit?
    #~ dup = `grep #{commit['id']} sha1s.txt`.size > 0
    #~ if not dup
      #~ `echo #{commit['id']} >> sha1s.txt`
      #~ 
      #~ dup = `grep #{commit['timestamp']} timestamps.txt`.size > 0
      #~ `echo #{commit['timestamp']} >> timestamps.txt` unless dup
    #~ end
    #~ 
    #~ if dup
      #~ next if data['repository']['fork'] || !(commit['message'] =~ /^Merge remote branch/)
      #~ commit['message'] << ' (merged into upstream from fork --FBI)'
    #~ end
    
    output = {
      :project => data['repository']['name'],
      :owner => data['repository']['owner']['name'],
      :fork => data['repository']['fork'],
      :author => commit['author'],
      :branch => data['ref'].split('/').last,
      :commit => commit['id'],
      :message => commit['message'],
      :url => commit['url']
    }
    FBI::Client.publish 'commits', output
  end
  FBI::Client.publish 'github', data
}

Webhooks = Rack::Builder.new do
  use Rack::Reloader, 0
  use Rack::ContentLength
  app = proc do |env|
    if Hooks.has_key? env['PATH_INFO']
      Hooks[env['PATH_INFO']].call env
      [200, {'Content-Type' => 'text/plain'}, "Hook processed."]
    else
      [500, {'Content-Type' => 'text/plain'}, "No such hook."]
    end
  end
  run app
end.to_app

EM.next_tick do
  FBI::Client.connect 'thin', 'hil0l'
end
