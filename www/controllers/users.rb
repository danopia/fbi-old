class UsersController < Controller
  attr_reader :users, :user, :login2, :message
  
  def list captures, params, env
    @users = User.all
  end
  
  def show captures, params, env
    if params[:self]
      @user = env[:user]
    else
      @user = User.find :username => captures.first
      raise HTTP::NotFound unless @user
    end
    
    render :context => {
      :user => @user,
      :is_self => (@user == env[:user])
    }
  end
end
