class Commit < FBI::Model
  attr_accessor :json
  
  def initialize data={}
    super
    @json = JSON.parse @data[:json] if @data.has_key? :json
  end
  
  def repo
    Repo.find @data[:repo_id]
  end
  
  def committed_date
    Time.parse(@json['committed_date']).utc.strftime('%B %d, %Y') # %I:%M %p
  end
  
  def short_message
    return @json['message'] if @json['message'].size <= 50
    @json['message'][0,47] + '...'
  end
  
  def short_hash
    @json['id'][0,8]
  end
  
  def author
    @json['author']['name']
  end
end
