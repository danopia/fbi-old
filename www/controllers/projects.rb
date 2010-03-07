class ProjectsController < Mustache
  attr_reader :project, :projects, :repo, :repos, :commits
  
  def do_main env, path
    @projects = Project.all
  end
  
  def do_show env, path
    @project = Project.from_slug path.first
  end
  
  def do_repos env, path
    @project = Project.from_slug path.first
    @repo = @project.repo_by_id path[2].to_i
  end
  
  def do_commits env, path
    @project = Project.from_slug path.first
    
    if path.size == 2 || path[2] != 'repos'
      @repos = @project.repos
    else
      @repo = @project.repo_by_id path[3].to_i
      @repos = [@repo]
    end
    
    if path.size > 2 && path[2] == 'authors'
      @commits = Commits.filter(:repo_id => @repos.map{|r| r.id }, :author => CGI::unescape(path[3])).reverse_order(:committed_at).all
    else
      @commits = Commits.filter(:repo_id => @repos.map{|r| r.id }).reverse_order(:committed_at).all
    end
    
    @commits.map! do |commit|
      Commit.new commit
    end
  end
end
