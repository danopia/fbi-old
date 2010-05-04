class Commit < FBI::Model
  attr_accessor :json
  
  def initialize data={}
    super
    @json = JSON.parse @data[:json] if @data.has_key? :json
  end

  def message; @data[:title]; end
  def hash; @data[:slug]; end
  def created_at; @data[:created_at]; end
  def service_id; @data[:service_id]; end
  def service_id; @data[:service_id]; end
  def project_id; @data[:project_id]; end
  
  def title= new; @data[:title] = new; end
  def slug= new; @data[:slug] = new; end
  def service_id= new; @data[:service_id] = new; end
  def name= new; @data[:name] = new; end
  def url= new; @data[:url] = new; end
  def project_id= new; @data[:project_id] = new; end

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
