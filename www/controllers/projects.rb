class ProjectsController < Controller
  attr_reader :project, :projects, :mine
  
  def main captures, params, env
    @projects = Project.all
  end
  
  def show captures, params, env
    @project = Project.find :slug => captures.first
    @mine = @project.owner == env[:user]
  end
end
