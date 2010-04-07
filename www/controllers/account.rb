class AccountController < Controller
  attr_reader :user, :message
  
  def edit captures, params, env
    raise HTTP::Found, '/account/new' if !env[:user]
    
    @user = env[:user]
    return unless post?
  
    @user.name = form_fields['name']
    @user.website = form_fields['website']
    @user.email = form_fields['email']
    @user.company = form_fields['company']
    @user.location = form_fields['location']
    @user.save
    
    #render :text => 'Your profile has been updated.'
    raise HTTP::Found, @user.profile_path
  end
  
  def new captures, params, env
    @user = User.new
    return unless post?
    
    return unless form_fields['password'] == form_fields['password_confirm']
    
    @user.username = form_fields['username']
    @user.email = form_fields['email']
    @user.password = form_fields['password']
    @user.save
    
    @env[:user] = @user
    @env[:session] = @user.create_session env['REMOTE_ADDR']
    
    #render :text => 'Your account has been registered.'
    raise HTTP::Found, @user.profile_path
  end
  
  def login captures, params, env
    return unless post?
    
    @user = User.find :username => form_fields['username']
    
    if @user.password_hash == User.hash(@user.username.downcase, @user.salt, form_fields['password'])
      env[:session] = @user.create_session env['REMOTE_ADDR']
      env[:user] = @user
      
      #render :text => 'You have logged in.'
      raise HTTP::Found, @user.profile_path
    else
      @message = 'The username or password was incorrect.'
    end
  end
  
  def logout captures, params, env
    raise HTTP::Forbidden, 'You are not logged in.' if !env[:session]
    
    # Expire the cookie
    cookie = CGI::Cookie.new 'fbi_session', ''
    cookie.expires = Time.at(0)
    cookie.path = '/'
    env[:headers]['Set-Cookie'] = cookie.to_s
    
    env[:session].destroy!
    
    env[:user] = nil
    env[:session] = nil

    #render :text => 'You have logged out.'
    raise HTTP::Found, '/'
  end
end
