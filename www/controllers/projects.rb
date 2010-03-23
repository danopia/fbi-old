class ProjectsController < Controller
  attr_reader :project, :projects, :mine, :users
  
  def main captures, params, env
    @projects = Project.all
  end
  
  def show captures, params, env
    @project = Project.find :slug => captures.first
    @mine = @project.owner? env[:user] if env[:user]
  end
  
  def new captures, params, env
    @project = Project.new
    
    if env['REQUEST_METHOD'] == 'POST'
      data = CGI.parse env['rack.input'].read
      
      @project.title = data['title'].first
      @project.slug = data['slug'].first
      
      @project.save
      
      project_member = ProjectMember.create :user_id => env[:user].id, :project_id => @project.id, :owner => true

      #render :text => 'The project has been registered.'
      
      @mine = true
      render :path => 'projects/show'
    end
  end
  
  def edit captures, params, env
    @project = Project.find :slug => captures[0]
    return unless @project.owner? env[:user]
    
    if env['REQUEST_METHOD'] == 'POST'
      data = CGI.parse env['rack.input'].read
      
      @project.title = data['title'].first
      @project.slug = data['slug'].first
      
      @project.save
      
      #render :text => 'The project has been updated.'
      @mine = true
      render :path => 'projects/show'
    end
  end
  
  def add_member captures, params, env
    @project = Project.find :slug => captures[0]
    return unless @project.owner? env[:user]
    @project_member = ProjectMember.new :project_id => @project.id
    
    if env['REQUEST_METHOD'] == 'POST'
      data = CGI.parse env['rack.input'].read
      
      member = User.find :username => data['username'].first
      return unless member
      
      @project_member.user = member
      @project_member.owner = data['owner'].any?
      @project_member.save

      #render :text => 'The member has been added.'
      
      @mine = true
      render :path => 'projects/show'
    else
      @users = User.all
      existing = @project.members.map &:user_id
      @users.reject! {|user| existing.include? user.id }
    end
  end
end
