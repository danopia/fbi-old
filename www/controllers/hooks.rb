require 'cgi'
require 'json'

class HooksController < Controller

  def github captures, params, env
    raise HTTP::OK, 'This is a webhook receiver.' unless post?
    data = JSON.parse form_fields['payload']
    
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
    env[:fbi].send '#commits', output
    env[:fbi].send '#github', data
    
    raise HTTP::OK, 'Hook processed.'
  end

  def bitbucket captures, params, env
    raise HTTP::OK, 'This is a webhook receiver.' unless post?
    data = JSON.parse form_fields['payload']
    
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
    env[:fbi].send '#commits', output
    env[:fbi].send '#bitbucket', data
    
    raise HTTP::OK, 'Hook processed.'
  end
  
end


