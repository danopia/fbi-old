class ProjectsController < Controller
  attr_reader :project, :projects, :debug
  
  def main captures, params, env
    @projects = Project.all
    
    @user = User.load env
    @debug = @user.inspect
  end
  
  def show captures, params, env
    @project = Project.from_slug captures.first
  end
end
