require 'yaml'
require 'open-uri'

require 'time'

def load_api *args
	YAML.load open("http://github.com/api/v2/yaml/#{args.join '/'}").read
end

require 'rubygems'
require 'sequel'
require 'json'

DB = Sequel.sqlite('www.db')
Commits = DB[:commits]
Repos = DB[:repos]
Projects = DB[:projects]
Pages = DB[:pages]
Users = DB[:users]

#DB.drop_table :users
DB.create_table :users do
  primary_key :id
  
  String :username, :unique => true, :null => false
  String :name
  String :email, :null => false
  String :website
  String :company
  String :location
  String :password_hash, :null => false
  
  String :cookie_token, :unique => true
  
  Time :created_at, :null => false
  Time :modified_at
end

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

DB.create_table :pages do
  primary_key :id
  
  String :slug
  String :title
  String :contents
  foreign_key :project_id, :projects
  
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
