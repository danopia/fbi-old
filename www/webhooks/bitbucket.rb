require 'cgi'
require 'json'

class BitbucketHook
  def run env, fbi
    data = env['rack.input'].read
    data = JSON.parse CGI::unescape(data[8..-1])
    
    output = data['commits'].map do |commit|
      {
        :project => data['repository']['name'],
        :owner => data['repository']['owner'],
        :fork => false,
        :author => {:email => nil, :name => commit['author'].strip},
        :branch => commit['branch'],
        :commit => commit['node'],
        :message => commit['message'],
        :url => "http://bitbucket.org/#{data['repository']['owner']}/#{data['repository']['slug']}/changeset/#{commit['node']}"
      }
    end
    fbi.send '#commits', output
    fbi.send '#bitbucket', data
  end
end
