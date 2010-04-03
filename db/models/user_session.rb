class UserSession < FBI::Model
  
  def user_id; @data[:user_id]; end
  def ip_address; @data[:ip_address]; end
  def cookie_token; @data[:cookie_token]; end
  
  def ip_address= new; @data[:ip_address] = new; end
  def cookie_token= new; @data[:cookie_token] = new; end
  
  def user; @user ||= User.find(:id => @data[:user_id]); end
  def user= new; @user = new; @data[:user_id] = new.id; end
  
  def save
    @data[:cookie_token] ||= UserSession.random_token if new_record?
    super
  end
  
  def self.random_token length=256
    (1..length).map {|i| rand(16).to_s(16) }.join('')
  end
  def new_token length=256
    @data[:cookie_token] = UserSession.random_token(length)
  end
  
  
  def create_cookie
    @data[:cookie_token] ||= UserSession.random_token
    cookie = CGI::Cookie.new 'fbi_session', @data[:cookie_token]
    cookie.expires = Time.now + (60*60*24*30*3)
    cookie.path = '/'
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
