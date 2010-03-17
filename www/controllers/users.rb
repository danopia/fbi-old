class UsersController < Controller
  attr_reader :users, :user, :register, :login2, :message
  
  def list captures, params, env
    @users = User.all
  end
  
  def show captures, params, env
    @user = User.from_username captures.first
  end
  
  def new captures, params, env
    @user = User.new
    
    if env['REQUEST_METHOD'] == 'POST'
      data = CGI.parse env['rack.input'].read
      
      @user.username = data['username'].first
      @user.email = data['email'].first
      
      @user.password = data['password'].first
      return unless data['password'] == data['password_confirm']
      
      @user.cookie_token = User.random_token
      @cookie = CGI::Cookie.new 'fbi_session', @user.cookie_token
      @cookie.expires = Time.now + (60*60*24*30*3)
      
      @user.save
      
      $headers['Set-Cookie'] = @cookie.to_s
      
      @message = 'Your account has been registered.'
    else
      @register = true
    end
  end
  
  def login captures, params, env
    if env['REQUEST_METHOD'] == 'POST'
      data = CGI.parse env['rack.input'].read
      @user = User.find :username => data['username'].first
      
      if @user.password_hash == User.hash(data['password'].first)
        @user.cookie_token = User.random_token
        @cookie = CGI::Cookie.new 'fbi_session', @user.cookie_token
        @cookie.expires = Time.now + (60*60*24*30*3)
        
        @user.save
        
        $headers['Set-Cookie'] = @cookie.to_s
        
        @message = 'You have logged in.'
      else
        @message = 'The username or password was incorrect.'
        @login2 = true
      end
    else
      @login2 = true
    end
  end
  
  def logout captures, params, env
    @user = User.load env
    return unless @user
    
    cookie = CGI::Cookie.new 'fbi_session', ''
    cookie.expires = Time.at(0)
    $headers['Set-Cookie'] = cookie.to_s
  end
end
