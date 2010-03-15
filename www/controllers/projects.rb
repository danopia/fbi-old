class ProjectsController < Mustache
  attr_reader :project, :projects
  
  def main captures, params, env
    @projects = Project.all
  end
  
  def show captures, params, env
    @project = Project.from_slug captures.first
  end
end
