class IrcChannelsController < Controller
  attr_reader :network, :channel, :channels
  
  # TODO: Goes in IrcNetwork
  def parse_network_url url
    host, port = url.split ':', 2
    {:hostname => host, :port => port.to_i}
  end
  
  def lookup_channel captures
    @network = IrcNetwork.find parse_network_url(captures[0])
    raise HTTP::NotFound unless @network
    
    return if captures.size < 2
    @channel = @network.channel_by :name => CGI::unescape(captures[1]).downcase
    raise HTTP::NotFound unless @channel
  end
  
  
  #~ def list captures, params, env
    #~ @network = IrcNetwork.find parse_network_url(captures[0])
    #~ raise HTTP::NotFound unless @network
    #~ 
    #~ @channels = @network.channels
  #~ end
  
  def show captures, params, env
    lookup_channel captures
    
    @users = FBI::Model.fbi_packet {:mode => 'users', :channel_id => @channel.id}, '#irc'
    p @users
    
    #~ @joined = @project.member? env[:user] if env[:user]
    #~ @mine = @joined.owner? if @joined
    #~ @unjoined = !@joined
  end
  
  def new captures, params, env
    @network = IrcNetwork.find parse_network_url(captures[0])
    raise HTTP::NotFound unless @network
    
    @channel = @network.new_channel
    return unless post?
    
    @channel.name = form_fields['name']
    @channel.save

    #render :text => 'The network has been added.'
    raise HTTP::Found, @channel.show_path
  end
  
  #~ def edit captures, params, env
    #~ lookup_channel captures
    #~ 
    #~ return unless post?
    #~ 
    #~ @network.hostname = form_fields['hostname']
    #~ @network.port = form_fields['port'].to_i
    #~ @network.save
#~ 
    #~ #render :text => 'The network has been added.'
    #~ raise HTTP::Found, @channel.show_path
  #~ end
  
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
