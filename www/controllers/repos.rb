class ReposController < Mustache
  attr_reader :project, :repo, :repos, :commits, :pages
  
  def list captures, params, env
    @project = Project.from_slug captures.first
    @repos = @project.repos
  end
  
  def show captures, params, env
    @project = Project.from_slug captures.first
    @repo = @project.repo_by_id captures[1].to_i
  end
end
