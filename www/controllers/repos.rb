class ReposController < Controller
  attr_reader :project, :repo, :repos, :commits, :pages, :debug, :files, :filename, :parent, :services, :mine
  
  def new captures, params, env
    @project = Project.find :slug => captures.first
    raise HTTP::NotFound unless @project
    raise HTTP::Forbidden unless @project.owner? env[:user]
    
    @repo = @project.new_repo
    
    unless post?
      @services = Service.all
      return
    end
    
    @repo.title = form_fields['title']
    @repo.slug = form_fields['slug']
    @repo.service_id = form_fields['service_id'].to_i
    @repo.name = form_fields['name']
    @repo.save
    
    #render :text => 'The repository has been added.'
    raise HTTP::Found, @repo.show_path
  end
  
  def edit captures, params, env
    @project = Project.find :slug => captures.first
    raise HTTP::NotFound unless @project
    raise HTTP::Forbidden unless @project.owner? env[:user]
    
    @repo = @project.repo_by :slug => captures[1]
    raise HTTP::NotFound unless @repo
    
    unless post?
      @services = Service.all
      @services.delete_if {|service| @repo.service_id == service.id }
      return
    end
    
    @repo.title = form_fields['title']
    @repo.slug = form_fields['slug']
    @repo.service_id = form_fields['service_id'].to_i
    @repo.name = form_fields['name']
    @repo.save
    
    #render :text => 'The repository has been updated.'
    raise HTTP::Found, @repo.show_path
  end
  
  def show captures, params, env
    @project = Project.find :slug => captures.first
    raise HTTP::NotFound unless @project
    
    @repo = @project.repo_by :slug => captures[1]
    raise HTTP::NotFound unless @repo
    
    @joined = @project.member? env[:user] if env[:user]
    @mine = @joined.owner? if @joined
    @unjoined = !@joined
  end
  
  def list captures, params, env
    @project = Project.find :slug => captures.first
    raise HTTP::NotFound unless @project
    raise HTTP::Forbidden unless @project.owner? env[:user]
    
    @repos = @project.repos
  end
  
  def tree captures, params, env
    @project = Project.find :slug => captures.first
    raise HTTP::NotFound unless @project
    raise HTTP::Forbidden unless @project.owner? env[:user]
    
    @repo = @project.repo_by :slug => captures[1]
    raise HTTP::NotFound unless @repo
    
		@repo_path = File.join(File.dirname(__FILE__), '..', 'repos', @repo.id.to_s)
    
    captures += [''] if captures.size == 2
    
    root = (captures[2] == '') ? '' : "#{captures[2]}/"
    @parent = File.dirname captures[2] if captures[2] != ''
    
    @files = `cd #{@repo_path}; git ls-tree master:#{captures[2]}`.scan(/^(\d+)\s+([a-z]+)\s+([a-f0-9]+)\s+(.+)/).map do |parts|
      {:modes => parts[0], :type => parts[1], :hash => parts[2], :path => "#{root}#{parts[3]}", :name => parts[3], parts[1].to_sym => true}
    end
  end
  
  def blob captures, params, env
    @project = Project.find :slug => captures.first
    raise HTTP::NotFound unless @project
    raise HTTP::Forbidden unless @project.owner? env[:user]
    
    @repo = @project.repo_by :slug => captures[1]
    raise HTTP::NotFound unless @repo
    
		@repo_path = File.join(File.dirname(__FILE__), '..', 'repos', @repo.id.to_s)
    
    @filename = captures[2]
    @parent = File.dirname @filename
    @debug = `cd #{@repo_path}; git show master:#{captures[2]}`
  end
end
