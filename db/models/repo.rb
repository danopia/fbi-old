class Repo < FBI::Model

  def title; @data[:title]; end
  def slug; @data[:slug]; end
  def service_id; @data[:service_id]; end
  def name; @data[:name]; end
  def url; @data[:url]; end
  def project_id; @data[:project_id]; end
  
  def title= new; @data[:title] = new; end
  def slug= new; @data[:slug] = new; end
  def service_id= new; @data[:service_id] = new; end
  def name= new; @data[:name] = new; end
  def url= new; @data[:url] = new; end
  def project_id= new; @data[:project_id] = new; end

  def project; @project ||= Project.find(:id => @data[:project_id]); end
  def project= new; @project = new; @data[:project_id] = new.id; end

  def service; @service ||= Service.find(:id => @data[:service_id]); end
  def service= new; @service = new; @data[:service_id] = new.id; end
  
  def full_id
    [service.slug, name].join ':'
  end
  
  #~ def commits
    #~ DB[:commits].filter(:repo_id => @id).reverse_order(:committed_at).all.map {|c| Commit.new c}
  #~ end
  #~ 
  #~ def commits_5
    #~ DB[:commits].filter(:repo_id => @id).reverse_order(:committed_at).first(5).map {|c| Commit.new c}
  #~ end
  
  def project_path; "/projects/#{project.slug}"; end
  def show_path;    "#{project_path}/repos/#{slug}"; end
  def edit_path;    "#{show_path}/edit"; end
  
  def project_link; project.show_link; end
  def show_link;    "<a href=\"#{show_path}\">#{title}</a>"; end
  def full_link;    [project_link, show_link].join ' / '; end
end
