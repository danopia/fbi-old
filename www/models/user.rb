require 'digest/sha2'

class User
  attr_reader :id, :data
  
  def self.from_id id
    self.new Users.filter(:id => id).first
  end
  
  def self.from_username username
    u = Users.filter(:username => username).first
    u && self.new(u)
  end
  
  def self.find filters
    u = Users.filter(filters).first
    u && self.new(u)
  end
  
  def self.where filters
    Users.filter(filters).map {|u| self.new u }
  end
  
  def self.all
    Users.all.map {|u| self.new u }
  end
  
  
  def initialize data={}
    @data = data
    @id = @data[:id]
    @data.delete :id
  end
  
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
  
  def created_at; @data[:created_at]; end
  def modified_at; @data[:modified_at]; end
  
  def display_name; name || username; end
  
  def save
    if @id
      @data[:modified_at] = Time.now
      Users.where(:id => @id).update @data
    else
      @data[:created_at] = Time.now
      @id = Users << @data
    end
  end
  
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
  
  
  def == other
    other.class == self.class && other.data == self.data
  end
  
  
  
  def create_session ip=nil
    save unless @id # so we have an ID
    
    session = UserSession.new :ip_address => ip, :user_id => @id
    session.save
    
    $headers['Set-Cookie'] = session.create_cookie.to_s # TODO: Nicer cookie codez
    
    session
  end
end
