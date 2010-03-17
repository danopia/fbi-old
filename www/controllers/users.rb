class UsersController < Controller
  attr_reader :users, :user, :register, :login2, :message
  
  def list captures, params, env
    @users = User.all
  end
  
  def show captures, params, env
    @user = User.find :username => captures.first
    render :context => @user
  end
  
  def new captures, params, env
    @user = User.new
    
    if env['REQUEST_METHOD'] == 'POST'
      data = CGI.parse env['rack.input'].read
      
      @user.username = data['username'].first
      @user.email = data['email'].first
      
      @user.password = data['password'].first
      return unless data['password'] == data['password_confirm']
      
      @user.save
      
      @env[:user] = @user
      @env[:session] = @user.create_session env['REMOTE_ADDR']
      
      @message = 'Your account has been registered.'
    else
      @register = true
    end
  end
  
  def login captures, params, env
    if env['REQUEST_METHOD'] == 'POST'
      data = CGI.parse env['rack.input'].read
      env[:user] = @user = User.find(:username => data['username'].first)
      
      if @user.password_hash == User.hash(@user.username.downcase, @user.salt, data['password'].first)
        env[:session] = @user.create_session env['REMOTE_ADDR']
        env[:user] = @user
        
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
    return unless env[:session]
    
    cookie = CGI::Cookie.new 'fbi_session', ''
    cookie.expires = Time.at(0)
    $headers['Set-Cookie'] = cookie.to_s
    
    env[:session].destroy!
    
    env[:user] = nil
    env[:session] = nil
  end
end
