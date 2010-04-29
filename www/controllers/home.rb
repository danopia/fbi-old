class HomeController < Controller
  attr_reader :user, :loggedout, :users, :projects, :repos
  
  def index captures, params, env
    @user = env[:user]
    @loggedout = !@user
    
    @users = User.first(5)
    @projects = Project.first(5)
    @repos = Repo.first(5)
  end
end
