class IrcChannel < FBI::Model

  def name; @data[:name]; end
  def catchall; @data[:catchall]; end
  
  def hostname= new; @data[:hostname] = new; end
  def port= new; @data[:port] = new; end
  def title= new; @data[:title] = new; end
  def last_connected= new; @data[:last_connected] = new; end

  def subs filters={}
    fields[:channel_id] = @id
    IrcProjectSub.where(filters).each {|repo| repo.channel = self }
  end
  def sub_for project
    chan = IrcChannel.find :network_id => @id, :project_id => project.id
    chan.project = project
    chan.network = self
    chan
  end
  def new_sub project
    chan = IrcChannel.new
    chan.project = project
    chan.network = self
    chan
  end
  def create_sub project
    new_sub(project).save
  end
  
  # Get all projects with only one/two queries
  def projects
    project_ids = subs.map {|sub| sub.project_id }
    return [] if project_ids.empty? # only do one! yay me
    Project.where :id => project_ids
  end

  def network; @network ||= IrcNetwork.find(:id => @data[:network_id]); end
  def network= new; @network = new; @data[:network_id] = new.id; end
  
  # Can be nil
  def project; @project ||= @data[:project_id] && Project.find(:id => @data[:project_id]); end
  def project= new; @project = new; @data[:project_id] = new && new.id; end
  
  def network_path; network.show_path; end
  def show_path; "#{network.channels_path}/#{slug}"; end
  def edit_path; "#{show_path}/edit"; end
  def projects_path; "#{show_path}/projects"; end
  
  def network_link; network.show_link; end
  def show_link; "<a href=\"#{show_path}\">#{title}</a>"; end
  def full_link; "#{network_link} / #{show_link}"; end
end
