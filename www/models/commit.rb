class Commit
  attr_accessor :id, :json
  
  def self.from_id id
    self.new Commits.filter(:id => id).first
  end
  
  
  def initialize data=nil
    data ||= {}
    @data = data
    @id = data[:id]
    @json = JSON.parse @data[:json] if @data.has_key? :json
  end
  
  def repo
    Repo.from_id @data[:repo_id]
  end
  
  def committed_date
    Time.parse(@json['committed_date']).utc.strftime('%B %d, %Y') # %I:%M %p
  end
  
  def short_message
    return @json['message'] if @json['message'].size <= 500
    @json['message'][0,497] + '...'
  end
  
  def short_hash
    @json['id'][0,8]
  end
  
  def author
    @json['author']['name']
  end
end
