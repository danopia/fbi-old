class Project < FBI::Model

  def title; @data[:title]; end
  def slug; @data[:slug]; end
  
  def title= new; @data[:title] = new; end
  def slug= new; @data[:slug] = new; end

  def member? user
    ProjectMember.find :user_id => user.id, :project_id => @id
  end
  def owner? user
    ProjectMember.find :user_id => user.id, :project_id => @id, :owner => true
  end
  
  def repos filters={}
    filters[:project_id] = @id
    Repo.where(filters).each {|repo| repo.project = self }
  end
  def repo_by filters
    filters[:project_id] = @id
    Repo.find filters
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
  
  def members
    ProjectMember.where :project_id => @id
  end
  def owners
    ProjectMember.where :project_id => @id, :owner => true
  end
  
  #~ def commits
    #~ repos = self.repos.map {|repo| repo.id }
    #~ DB[:commits].filter(:repo_id => repos).reverse_order(:committed_at).all.map {|c| Commit.new c }
  #~ end
  #~ 
  #~ def commits_5
    #~ repos = self.repos.map {|repo| repo.id }
    #~ DB[:commits].filter(:repo_id => repos).reverse_order(:committed_at).first(5).map {|c| Commit.new c }
  #~ end
  
  def show_path; "/projects/#{slug}"; end
  def edit_path; "#{show_path}/edit"; end
  def wiki_path; "#{show_path}/wiki"; end
  
  def show_link; "<a href=\"#{show_path}\">#{title}</a>"; end
  def wiki_link; "<a href=\"#{wiki_path}\">wiki</a>"; end
end
