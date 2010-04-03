class ProjectsController < Controller
  attr_reader :project, :projects, :mine, :users, :joined, :unjoined
  
  def main captures, params, env
    @projects = Project.all
  end
  
  def show captures, params, env
    @project = Project.find :slug => captures.first
    raise HTTP::NotFound unless @project
    
    @joined = @project.member? env[:user] if env[:user]
    @mine = @joined.owner? if @joined
    @unjoined = !@joined
  end
  
  def new captures, params, env
    @project = Project.new
    return unless post?
    
    @project.title = form_fields['title']
    @project.slug = form_fields['slug']
    @project.save
    
    ProjectMember.create :user_id => env[:user].id, :project_id => @project.id, :owner => true

    #render :text => 'The project has been registered.'
    raise HTTP::Found, @project.show_path
  end
  
  def edit captures, params, env
    @project = Project.find :slug => captures[0]
    raise HTTP::NotFound unless @project
    raise HTTP::Forbidden unless @project.owner? env[:user]
    
    return unless post?
    
    @project.title = form_fields['title']
    @project.slug = form_fields['slug']
    @project.save
    
    #render :text => 'The project has been updated.'
    raise HTTP::Found, @project.show_path
  end
  
  def add_member captures, params, env
    @project = Project.find :slug => captures[0]
    raise HTTP::NotFound unless @project
    raise HTTP::Forbidden unless @project.owner? env[:user]
    
    @project_member = ProjectMember.new :project_id => @project.id
    
    unless post?
      @users = User.all
      existing = @project.members.map &:user_id
      @users.reject! {|user| existing.include? user.id }
      
      return
    end
    
    member = User.find :username => form_fields['username']
    return unless member
    
    @project_member.user = member
    @project_member.owner = form_fields['owner']
    @project_member.save

    #render :text => 'The member has been added.'
    raise HTTP::Found, @project.show_path
  end
  
  def join captures, params, env
    @project = Project.find :slug => captures[0]
    raise HTTP::NotFound unless @project
    
    unless @project && env[:user]
      raise HTTP::Forbidden, 'You need to sign in first.'
    end
    
    ProjectMember.create :project_id => @project.id,
                         :user_id => env[:user].id
    
    #render :text => 'You have joined the project.'
    raise HTTP::Found, @project.show_path
  end
end
