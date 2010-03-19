class Repo < Model

  def title; @data[:title]; end
  def slug; @data[:slug]; end
  def service; @data[:service]; end
  def name; @data[:name]; end
  def url; @data[:url]; end
  def project_id; @data[:project_id]; end
  
  def title= new; @data[:title] = new; end
  def slug= new; @data[:slug] = new; end
  def service= new; @data[:service] = new; end
  def name= new; @data[:name] = new; end
  def url= new; @data[:url] = new; end
  def project_id= new; @data[:project_id] = new; end

  def project; @project ||= Project.find(:id => @data[:project_id]); end
  def project= new; @project = new; @data[:project_id] = new.id; end
  
  def full_id
    [service, name].join ':'
  end
  
  def commits
    DB[:commits].filter(:repo_id => @id).reverse_order(:committed_at).all.map {|c| Commit.new c}
  end
  
  def commits_5
    DB[:commits].filter(:repo_id => @id).reverse_order(:committed_at).first(5).map {|c| Commit.new c}
  end
end
