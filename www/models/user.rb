require 'digest/sha1'

class User
  attr_reader :id
  
  def self.from_id id
    self.new Users.filter(:id => id).first
  end
  
  def self.from_username username
    self.new Users.filter(:username => username).first
  end
  
  def self.find filters
    self.new Users.filter(filters).first
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
  def cookie_token; @data[:cookie_token]; end
  
  def username= new; @data[:username] = new; end
  def name= new; @data[:name] = new; end
  def email= new; @data[:email] = new; end
  def website= new; @data[:website] = new; end
  def company= new; @data[:company] = new; end
  def location= new; @data[:location] = new; end
  def password_hash= new; @data[:password_hash] = new; end
  def cookie_token= new; @data[:cookie_token] = new; end
  
  def created_at; @data[:created_at]; end
  def modified_at; @data[:modified_at]; end
  
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
    @data[:password_hash] = User.hash password
  end
  
  def self.hash password
    # make bruteforcing much slower
    10.times { password = Digest::SHA1.hexdigest password }
    password
  end
  
  
  def self.random_token length=256
    (1..length).map {|i| rand(16).to_s(16) }.join('')
  end
  def random_token length=256
    self.cookie_token = User.random_token(length)
  end
  
  
  
  
  
  def self.load env
    user = nil
    
    cookies = CGI::Cookie.parse env['HTTP_COOKIE']
    cookie = cookies['fbi_session']
    
    if cookie && cookie.any? && (user = User.find(:cookie_token => cookie.first))
      user.cookie_token = User.random_token
      cookie.value = user.cookie_token
      cookie.expires = Time.now + (60*60*24*30*3)
      $headers['Set-Cookie'] = cookie.to_s
      
      user.save
    else
      cookie = nil
    end
    
    user
  end
end
