class Repo
  attr_accessor :id, :name
  
  def self.from_id id
    self.new Repos.filter(:id => id).first
  end
  
  
  def initialize data=nil
    data ||= {}
    @data = data
    @id = data[:id]
    @name = data[:name]
  end
  
  def short_name
    @name.split('/').last
  end
  
  def commits
    Commits.filter(:repo_id => @id).all.map {|c| Commit.new c}
  end
  
  def project
    Project.from_id @data[:project_id]
  end
end
