class IrcProjectSub < FBI::Model
  
  def network; @channel.network; end

  def channel_id; @data[:channel_id]; end
  def channel; @channel ||= IrcChannel.find(:id => @data[:channel_id]); end
  def channel= new; @channel = new; @data[:channel_id] = new.id; end
  
  def project_id; @data[:project_id]; end
  def project; @project ||= Project.find(:id => @data[:project_id]); end
  def project= new; @project = new; @data[:project_id] = new.id; end
  
  def network_path; @channel.network.show_path; end
  def channel_path; @channel.show_path; end
  def project_path; @project.show_path; end
  
  def network_link; @channel.network.show_link; end
  def channel_link; @channel.show_link; end
  def project_link; @project.show_link; end
end
