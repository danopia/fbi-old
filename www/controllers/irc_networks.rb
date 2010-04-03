class IrcNetworksController < Controller
  attr_reader :network, :networks
  
  def parse_from_url url
    host, port = url.split ':', 2
    {:hostname => host, :port => port.to_i}
  end
  
  
  def list captures, params, env
    @networks = IrcNetwork.all
  end
  
  def show captures, params, env
    @network = IrcNetwork.find parse_from_url(captures[0])
    raise HTTP::NotFound unless @network
    
    #~ @joined = @project.member? env[:user] if env[:user]
    #~ @mine = @joined.owner? if @joined
    #~ @unjoined = !@joined
  end
  
  def new captures, params, env
    @network = IrcNetwork.new
    return unless post?
    
    @network.title = 'New network'
    @network.hostname = form_fields['hostname']
    @network.port = form_fields['port'].to_i
    @network.save

    #render :text => 'The network has been added.'
    raise HTTP::Found, @network.show_path
  end
  
  def edit captures, params, env
    raise HTTP::Forbidden unless env[:user] && env[:user].id == 1
    
    @network = IrcNetwork.find parse_from_url(captures[0])
    raise HTTP::NotFound unless @project
    
    return unless post?
    
    @network.hostname = form_fields['hostname']
    @network.port = form_fields['port'].to_i
    @network.save

    #render :text => 'The network has been added.'
    raise HTTP::Found, @network.show_path
  end
  
  #~ def add_member captures, params, env
    #~ @project = Project.find :slug => captures[0]
    #~ raise HTTP::NotFound unless @project
    #~ raise HTTP::Forbidden unless @project.owner? env[:user]
    #~ 
    #~ @project_member = ProjectMember.new :project_id => @project.id
    #~ 
    #~ unless post?
      #~ @users = User.all
      #~ existing = @project.members.map &:user_id
      #~ @users.reject! {|user| existing.include? user.id }
      #~ 
      #~ return
    #~ end
    #~ 
    #~ member = User.find :username => form_fields['username']
    #~ return unless member
    #~ 
    #~ @project_member.user = member
    #~ @project_member.owner = form_fields['owner']
    #~ @project_member.save
#~ 
    #~ #render :text => 'The member has been added.'
    #~ raise HTTP::Found, @project.show_path
  #~ end
  #~ 
  #~ def join captures, params, env
    #~ @project = Project.find :slug => captures[0]
    #~ raise HTTP::NotFound unless @project
    #~ 
    #~ unless @project && env[:user]
      #~ raise HTTP::Forbidden, 'You need to sign in first.'
    #~ end
    #~ 
    #~ ProjectMember.create :project_id => @project.id,
                         #~ :user_id => env[:user].id
    #~ 
    #~ #render :text => 'You have joined the project.'
    #~ raise HTTP::Found, @project.show_path
  #~ end
end
