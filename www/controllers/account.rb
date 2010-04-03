class AccountController < Controller
  attr_reader :user, :message
  
  def edit captures, params, env
    @user = env[:user]
    
    if env['REQUEST_METHOD'] == 'POST'
      data = CGI.parse env['rack.input'].read

      @user.name = data['name'].first
      @user.website = data['website'].first
      @user.email = data['email'].first
      @user.company = data['company'].first
      @user.location = data['location'].first
      @user.save
      
      #render :text => 'Your profile has been updated.'
      raise Redirect, @user.profile_path
    end
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
      
      #render :text => 'Your account has been registered.'
      raise Redirect, @user.profile_path
    end
  end
  
  def login captures, params, env
    if env['REQUEST_METHOD'] == 'POST'
      data = CGI.parse env['rack.input'].read
      @user = User.find(:username => data['username'].first)
      
      if @user.password_hash == User.hash(@user.username.downcase, @user.salt, data['password'].first)
        env[:session] = @user.create_session env['REMOTE_ADDR']
        env[:user] = @user
        
        #render :text => 'You have logged in.'
        raise Redirect, @user.profile_path
      else
        @message = 'The username or password was incorrect.'
      end
    end
  end
  
  def logout captures, params, env
    unless env[:session]
      render :text => 'You are not logged in.'
      return
    end
    
    # Expire the cookie
    cookie = CGI::Cookie.new 'fbi_session', ''
    cookie.expires = Time.at(0)
    cookie.path = '/'
    $headers['Set-Cookie'] = cookie.to_s
    
    env[:session].destroy!
    
    env[:user] = nil
    env[:session] = nil

    #render :text => 'You have logged out.'
    raise Redirect, '/'
  end
end
