require File.join(File.dirname(__FILE__), '..', 'common', 'client')
require 'cgi'

require 'yaml'
require 'open-uri'

require 'time'

def load_api *args
	YAML.load open("http://github.com/api/v2/yaml/#{args.join '/'}").read
end

require 'rubygems'
require 'sequel'
require 'json'
require 'mustache'

DB = Sequel.sqlite('www.db')
Commits = DB[:commits]
Repos = DB[:repos]
Projects = DB[:projects]

unless DB.table_exists? :commits
  DB.create_table :commits do
    primary_key :id
    
    String :author, :null => false
    foreign_key :repo_id, :repos
    String :hash, :null => false
    String :json, :null => false
    Time :committed_at, :null => false
  end
  
  DB.create_table :repos do
    primary_key :id
    
    String :name
    String :url
    foreign_key :project_id, :projects
    
    Time :created_at, :null => false
    Time :modified_at
  end
  
  DB.create_table :projects do
    primary_key :id
    
    String :title, :null => false
    String :slug, :unique => true, :null => false
    
    Time :created_at, :null => false
    Time :modified_at
  end
  
  Projects << {:title => 'ooc', :slug => 'ooc', :created_at => Time.now}
  Projects << {:title => 'FBI', :slug => 'fbi', :created_at => Time.now}
  
  ['nddrylliog/ooc', 'nddrylliog/nagaqueen', 'nddrylliog/rock', 'danopia/remora', 'danopia/fbi', 'nddrylliog/greg', 'nddrylliog/yajit', 'nddrylliog/ooc-curl'].each do |project|
    proj = project.include?('ndd') ? 1 : (project == 'danopia/fbi' ? 2 : nil)
    Repos << {:project_id => proj, :name => project, :url => "http://github.com/#{project}", :created_at => Time.now}
    repo = Repos.filter(:name => project).first[:id]
    
    load_api('commits', 'list', project, 'master')['commits'].each do |data|
      Commits << {
        :author => data['author']['name'],
        :repo_id => repo,
        :hash => data['id'],
        :committed_at => Time.parse(data['committed_date']),
        :json => data.to_json,
      }
    end
  end
end



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
  FBI::Client.publish 'commits', output
  FBI::Client.publish 'github', data
}

Hooks['/bitbucket'] = lambda {|env|
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
  FBI::Client.publish 'commits', output
  FBI::Client.publish 'bitbucket', data
}

class Project < Mustache
  #self.template_path = File.dirname(__FILE__) + '/views'
  self.template_file = File.dirname(__FILE__) + '/views/commit_timeline.mustache'
  
  attr_accessor :data, :title, :slug, :repos, :commits
  
  def initialize data=nil
    data ||= {}
    @data = data
    @title = data[:title]
    @slug = data[:slug]
  end
end

def handle_project env
  path = env['PATH_INFO'].split('/')[2..-1]
  message = ''
  
  project = Project.new Projects.filter(:slug => path.first).first
  if path.size == 1 || path[1] != 'repos'
    project.repos = Repos.filter(:project_id => project.data[:id]).all.map do |repo|
      repo[:short] = repo[:name].split('/').last
      repo
    end
  else
    repo = Repos.filter(:project_id => project.data[:id], :id => path[2].to_i).first
    repo[:short] = repo[:name].split('/').last
    project.repos = [repo]
  end
  
  if path.size > 1 && path[1] == 'authors'
    project.commits = Commits.filter(:repo_id => project.repos.map{|r| r[:id] }, :author => CGI::unescape(path[2])).reverse_order(:committed_at).all
  else
    project.commits = Commits.filter(:repo_id => project.repos.map{|r| r[:id] }).reverse_order(:committed_at).all
  end
  
  project.commits.map! do |commit|
    data = JSON.parse commit[:json]
    data[:repo] = project.repos.find{|r| r[:id] == commit[:repo_id] }
    data['committed_date'] = Time.parse(data['committed_date']).utc.strftime('%B %d, %Y') # %I:%M %p
    data['short_message'] = data['message'][0,500]
    data['short_message'] << '...' if data['message'].size > data['short_message'].size
    data['short_hash'] = data['id'][0,8]
    data
  end
  
  [200, {'Content-Type' => 'text/html'}, project.render]
end

Webhooks = Rack::Builder.new do
  use Rack::Reloader, 0
  use Rack::ContentLength
  app = proc do |env|
    if Hooks.has_key? env['PATH_INFO']
      Hooks[env['PATH_INFO']].call env
      [200, {'Content-Type' => 'text/plain'}, "Hook processed."]
    elsif env['PATH_INFO'] =~ /^\/projects\/(.*)$/
      handle_project env
    else
      [404, {'Content-Type' => 'text/plain'}, "No such hook."]
    end
  end
  run app
end.to_app

EM.next_tick do
  FBI::Client.connect 'thin', 'hil0l'
end
