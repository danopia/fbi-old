require 'digest/sha2'

class User < Model

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
  
  
  
  def create_session ip=nil
    save if new_record? # so we have an ID
    
    session = UserSession.create :ip_address => ip, :user_id => @id
    $headers['Set-Cookie'] = session.create_cookie.to_s # TODO: Nicer cookie codez
    session
  end
  
  def projects filters={}
    filters[:id] = member_of.map {|mo| mo.project_id }
    Project.where filters
  end
  
  def member_of
    ProjectMember.where :user_id => @id
  end
  
  def profile_path; "/users/#{username}"; end
  
  def profile_link; "<a href=\"#{profile_path}\" title=\"#{display_name}'s Profile\">#{display_name}</a>"; end
end
