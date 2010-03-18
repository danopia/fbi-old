class Repo < Model

  def name; @data[:name]; end
  def slug; @data[:slug]; end
  def url; @data[:url]; end
  def project_id; @data[:project_id]; end
  
  def name= new; @data[:name] = new; end
  def slug= new; @data[:slug] = new; end
  def url= new; @data[:url] = new; end
  def project_id= new; @data[:project_id] = new; end

  def project; @project ||= Project.find(:id => @data[:project_id]); end
  def project= new; @project = new; @data[:project_id] = new.id; end
  
  def short_name
    name.split('/').last
  end
  
  def commits
    Commits.filter(:repo_id => @id).reverse_order(:committed_at).all.map {|c| Commit.new c}
  end
  
  def commits_5
    Commits.filter(:repo_id => @id).reverse_order(:committed_at).first(5).map {|c| Commit.new c}
  end
end
