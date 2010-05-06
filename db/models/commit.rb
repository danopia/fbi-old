class Commit < FBI::Model
  attr_accessor :json
  
  def initialize data={}
    super
    @json = JSON.parse @data[:json] if @data.has_key? :json
  end
  
  def save *args
    @data[:json] = @json.to_json
    super
  end

  def message; @data[:message]; end
  def hash; @data[:hash]; end
  def committed_at; @data[:committed_at]; end
  def repo_id; @data[:repo_id]; end
  def author_id; @data[:author_id]; end
  def identity_id; @data[:identity_id]; end
  
  def message= new; @data[:message] = new; end
  def hash= new; @data[:hash] = new; end
  def committed_at= new; @data[:committed_at] = new; end
  def repo_id= new; @data[:repo_id] = new; end
  def author_id= new; @data[:author_id] = new; end
  def identity_id= new; @data[:identity_id] = new; end

  def repo; @repo ||= Repo.find(:id => @data[:repo_id]); end
  def repo= new; @repo = new; @data[:repo_id] = new.id; end

  def author; @author ||= User.find(:id => @data[:author_id]); end
  def author= new; @author = new; @data[:author_id] = new.id; end

  def identity; @identity ||= Identities.find(:id => @data[:identity_id]); end
  def identity= new; @identity = new; @data[:identity_id] = new.id; end
  
  def committed_date
    Time.parse(@json['committed_date']).utc.strftime('%B %d, %Y') # %I:%M %p
  end
  
  def short_message
    return @message if @message.size <= 50
    @message[0,47] + '...'
  end
  
  def short_hash
    @hash[0,8]
  end
  
  def author
    @json['author']['name']
  end
end
