require 'rubygems'
require 'active_record'

# connect to the database
ActiveRecord::Base.establish_connection({
	:adapter => "sqlite3",
	:database => "irc.sqlite3"
})
 
class Project < ActiveRecord::Base
  validates_uniqueness_of :name
  
  has_many :project_subs
  has_many :channels, :through => :project_subs
end
 
class Server < ActiveRecord::Base
  validates_uniqueness_of :hostname
  
  has_many :channels
end
 
class Channel < ActiveRecord::Base
  validates_uniqueness_of :name, :scope => :server_id
  
  belongs_to :server
  has_many :project_subs
  has_many :projects, :through => :project_subs
end
 
class ProjectSub < ActiveRecord::Base
  validates_uniqueness_of :project_id, :scope => :channel_id
  
  belongs_to :project
  belongs_to :channel
end
 
