require 'digest/sha2'

class User < FBI::Model

  def username; @data[:username]; end
  def name; @data[:name]; end
  def email; @data[:email]; end
  def website; @data[:website]; end
  def company; @data[:company]; end
  def location; @data[:location]; end
  def password_hash; @data[:password_hash]; end
  def salt; @data[:salt]; end
  
  def username= new; @data[:username] = new; end
  def name= new; @data[:name] = new; end
  def email= new; @data[:email] = new; end
  def website= new; @data[:website] = new; end
  def company= new; @data[:company] = new; end
  def location= new; @data[:location] = new; end
  def password_hash= new; @data[:password_hash] = new; end
  def salt= new; @data[:salt] = new; end
  
  def display_name; name || username; end
  
  def password= password
    self.salt ||= User.random_token
    self.password_hash = User.hash username.downcase, salt, password
  end
  
  # Username.downcase, salt, password
  def self.hash *args
    hash = args.join '-'
    # make bruteforcing much slower
    2.times { hash = Digest::SHA512.hexdigest hash }
    hash
  end
  
  
  def self.random_token length=256
    (1..length).map {|i| rand(16).to_s(16) }.join('')
  end
  
  
  
  def create_session env
    save if new_record? # so we have an ID
    
    session = UserSession.create :ip_address => env['REMOTE_ADDR'], :user_id => @id
    env[:headers]['Set-Cookie'] = session.create_cookie.to_s # TODO: Nicer cookie codez
    session
  end
  
  def projects filters={}
    filters[:id] = memberships.map {|mo| mo.project_id }
    Project.where filters
  end
  
  def memberships
    members = ProjectMember.where :user_id => @id
    projects = Project.where(:id => members.map{|mem| mem.project_id}).map {|project| [project.id, project] }
    members.each {|mem| mem.project = projects.assoc(mem.project_id)[1] }
  end
  
  def identities filters={}
    filters[:user_id] = @id
    Identity.where(filters).each {|identity| identity.user = self }
  end
  def new_identity fields={}
    save if new_record? # so we have an ID
    fields[:user_id] = @id
    Identity.new fields
  end
  def create_identity fields={}
    save if new_record? # so we have an ID
    fields[:user_id] = @id
    Identity.create fields
  end
  
  
  def profile_path; "/users/#{username}"; end
  
  def profile_link; "<a href=\"#{profile_path}\" title=\"#{display_name}'s Profile\">#{display_name}</a>"; end
end
