require 'cgi'
require 'json'

class GithubHook
  def run env, fbi
    data = env['rack.input'].read
    data = JSON.parse CGI::unescape(data[8..-1])
    
    output = data['commits'].map do |commit|
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
