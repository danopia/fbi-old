class ProjectsController < Controller
  attr_reader :project, :projects, :mine
  
  def main captures, params, env
    @projects = Project.all
  end
  
  def show captures, params, env
    @project = Project.find :slug => captures.first
    @mine = @project.owner == env[:user]
  end
  
  def new captures, params, env
    @project = Project.new
    
    if env['REQUEST_METHOD'] == 'POST'
      data = CGI.parse env['rack.input'].read
      
      @project.title = data['title'].first
      @project.slug = data['slug'].first
      
      @project.save
      
      #render :text => 'The project has been registered.'
      
      @mine = true
      render :path => 'projects/show'
    end
  end
end
