class Project
  attr_reader :id, :data, :slug, :title
  
  def self.from_slug slug
    self.new Projects.filter(:slug => slug).first
  end
  
  def self.from_id id
    self.new Projects.filter(:id => id).first
  end
  
  def self.all
    Projects.all.map {|p| self.new p }
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
  
  def commits
    repos = self.repos.map {|repo| repo.id }
    Commits.filter(:repo_id => repos).reverse_order(:committed_at).all.map {|c| Commit.new c }
  end
  
  def commits_5
    repos = self.repos.map {|repo| repo.id }
    Commits.filter(:repo_id => repos).reverse_order(:committed_at).first(5).map {|c| Commit.new c }
  end
end
