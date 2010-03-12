require 'cgi'
require 'json'

class GithubHook
  def run env, fbi
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
    
    output = data['commits'].map do |commit|
    
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
      
      {
        :project => data['repository']['name'],
        :owner => data['repository']['owner']['name'],
        :fork => data['repository']['fork'],
        :author => commit['author'],
        :branch => data['ref'].split('/').last,
        :commit => commit['id'],
        :message => commit['message'],
        :url => commit['url']
      }
    end
    fbi.publish 'commits', output
    fbi.publish 'github', data
  end
end
