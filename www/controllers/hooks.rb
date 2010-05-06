require 'cgi'
require 'json'

class HooksController < Controller

  def find_repo service_id, name
    Repo.find :service_id => service_id, :name => name
  end
  
  def publish_commits repo, commits, extras={}
    packet = extras # just for the param name
    packet[:commits] = commits
    packet[:repo_id] = repo.id
    packet[:project_id] = repo.project_id
    
    env[:fbi].send '#commits', packet
  end
  
  def save_commits repo, commits, extras={}
    commits.each do |commit|
      record = Commit.new
      record.json = extras + commit
      record.
    end
  end
  

  def github captures, params, env
    raise HTTP::OK, 'This is a webhook receiver.' unless post?
    
    data = JSON.parse form_fields['payload']
    env[:fbi].send '#github', data
    
    repo_name = [data['repository']['owner']['name'], data['repository']['name']].join '/'
    repo = find_repo 1, repo_name
    p repo
    
    return unless repo
    
    data['commits'].map! do |commit|
      {:author => commit['author'],
       :branch => data['ref'].split('/').last,
       :commit => commit['id'],
       :message => commit['message'],
       :url => commit['url']}
    end
    
    publish_commits repo, data['commits'], :branch => data['ref'].split('/').last
    
    raise HTTP::OK, 'Hook processed.'
  end

  def bitbucket captures, params, env
    #~ raise HTTP::OK, 'This is a webhook receiver.' unless post?
    #~ data = JSON.parse form_fields['payload']
    #~ 
    #~ output = data['commits'].map do |commit|
      #~ {
        #~ :project => data['repository']['name'],
        #~ :owner => data['repository']['owner'],
        #~ :fork => false,
        #~ :author => {:email => nil, :name => commit['author'].strip},
        #~ :branch => commit['branch'],
        #~ :commit => commit['node'],
        #~ :message => commit['message'],
        #~ :url => "http://bitbucket.org/#{data['repository']['owner']}/#{data['repository']['slug']}/changeset/#{commit['node']}"
      #~ }
    #~ end
    #~ env[:fbi].send '#commits', output
    #~ env[:fbi].send '#bitbucket', data
    #~ 
    #~ raise HTTP::OK, 'Hook processed.'
  end
  
end



