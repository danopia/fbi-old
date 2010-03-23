class HomeController < Controller
  attr_reader :user, :loggedout, :users, :projects, :repos
  
  def index captures, params, env
    @user = env[:user]
    @loggedout = !@user
    
    @users = User.all
    @projects = Project.all
    @repos = Repo.all
  end
end
