class IrcNetwork < FBI::Model

  def hostname; @data[:hostname]; end
  def port; @data[:port] ||= 6667; end
  def title; @data[:title]; end
  def last_connected; @data[:last_connected]; end
  
  def hostname= new; @data[:hostname] = new; end
  def port= new; @data[:port] = new; end
  def title= new; @data[:title] = new; end
  def last_connected= new; @data[:last_connected] = new; end

  def channels filters={}
    filters[:network_id] = @id
    IrcChannel.where(filters).each {|repo| repo.network = self }
  end
  def channel_by filters={}
    filters[:network_id] = @id
    IrcChannel.find filters
  end
  def new_channel fields={}
    fields[:network_id] = @id
    IrcChannel.new fields
  end
  def create_channel fields={}
    fields[:network_id] = @id
    IrcChannel.create fields
  end
  
  def slug; "#{hostname}:#{port}"; end
  
  def show_path; "/irc/networks/#{slug}"; end
  def edit_path; "#{show_path}/edit"; end
  def channels_path; "#{show_path}/channels"; end
  
  def show_link; "<a href=\"#{show_path}\">#{title}</a>"; end
end
