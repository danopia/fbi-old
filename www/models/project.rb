class Project < Model

  def title; @data[:title]; end
  def slug; @data[:slug]; end
  def owner_id; @data[:owner_id]; end
  
  def title= new; @data[:title] = new; end
  def slug= new; @data[:slug] = new; end
  def owner_id= new; @data[:owner_id] = new; end

  def owner; @owner ||= User.find(:id => @data[:owner_id]); end
  def owner= new; @owner = new; @data[:owner_id] = new.id; end
  
  def repos filters={}
    filters[:project_id] = @id
    Repo.where filters
  end
  def pages filters={}
    filters[:project_id] = @id
    Page.where filters
  end
  
  def repo_by filters
    filters[:project_id] = @id
    Repo.find filters
  end
  def page_by filters
    filters[:project_id] = @id
    Page.find filters
  end
  
  def new_repo fields={}
    fields[:project_id] = @id
    Repo.new fields
  end
  def create_repo fields={}
    fields[:project_id] = @id
    Repo.create fields
  end
  
  def created_at_short
    created_at.utc.strftime('%B %d, %Y')
  end
  
  def commits
    repos = self.repos.map {|repo| repo.id }
    DB[:commits].filter(:repo_id => repos).reverse_order(:committed_at).all.map {|c| Commit.new c }
  end
  
  def commits_5
    repos = self.repos.map {|repo| repo.id }
    DB[:commits].filter(:repo_id => repos).reverse_order(:committed_at).first(5).map {|c| Commit.new c }
  end
end
