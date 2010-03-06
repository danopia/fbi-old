class Project
  attr_reader :id, :data, :slug, :title
  
  def self.from_slug slug
    self.new Projects.filter(:slug => slug).first
  end
  
  def self.from_id id
    self.new Projects.filter(:id => id).first
  end
  
  
  def initialize data=nil
    data ||= {}
    @data = data
    @id = data[:id]
    @title = data[:title]
    @slug = data[:slug]
  end
  
  def repos
    Repos.filter(:project_id => @id).all.map {|r| Repo.new r}
  end
  
  def repo_by_id id
    Repo.new Repos.filter(:project_id => @id, :id => id).first
  end
  
  def created_at
    @data[:created_at].utc.strftime('%B %d, %Y')
  end
end
