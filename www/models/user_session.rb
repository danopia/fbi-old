class UserSession
  attr_reader :id
  
  def self.find filters
    us = UserSessions.filter(filters).first
    us && self.new(us)
  end
  
  def self.where filters
    UserSessions.filter(filters).map {|us| self.new us }
  end
  
  def self.all
    UserSessions.all.map {|us| self.new us }
  end
  
  
  def initialize data={}
    @data = data
    @id = @data[:id]
    @data.delete :id
  end
  
  def user_id; @data[:user_id]; end
  def ip_address; @data[:ip_address]; end
  def cookie_token; @data[:cookie_token]; end
  
  def ip_address= new; @data[:ip_address] = new; end
  def cookie_token= new; @data[:cookie_token] = new; end
  
  def created_at; @data[:created_at]; end
  def modified_at; @data[:modified_at]; end
  
  def user; @user ||= User.find(:id => @data[:user_id]); end
  def user= new; @user = new; @data[:user_id] = new.id; end
  
  def save
    if @id
      @data[:modified_at] = Time.now
      UserSessions.where(:id => @id).update @data
    else
      @data[:created_at] = Time.now
      @data[:cookie_token] ||= UserSession.random_token
      @id = UserSessions << @data
    end
  end
  
  def self.random_token length=256
    (1..length).map {|i| rand(16).to_s(16) }.join('')
  end
  def new_token length=256
    @data[:cookie_token] = UserSession.random_token(length)
  end
  
  
  def destroy!
    UserSessions.where(:id => @id).delete
  end
  
  
  def create_cookie
    @data[:cookie_token] ||= UserSession.random_token
    cookie = CGI::Cookie.new 'fbi_session', @data[:cookie_token]
    cookie.expires = Time.now + (60*60*24*30*3)
    cookie
  end
  
  
  def self.load env
    cookie = CGI::Cookie.parse(env['HTTP_COOKIE'])['fbi_session']
    
    return nil unless cookie && cookie.any?
    
    session = UserSession.find :cookie_token => cookie.first
    return nil unless session
    
    session.new_token
    session.ip_address = env['REMOTE_ADDR']
    $headers['Set-Cookie'] = session.create_cookie.to_s # TODO: Nicer cookie codez
    session.save
    
    session
  end
end
