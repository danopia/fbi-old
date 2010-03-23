class ProjectMember < Model
  
  def owner; @data[:owner]; end
  def owner= new; @data[:owner] = new; end
  
  def user_id; @data[:user_id]; end
  def project_id; @data[:project_id]; end
  
  def user_id= new; @data[:user_id] = new; end
  def project_id= new; @data[:project_id] = new; end
  
  def user; @user ||= User.find(:id => @data[:user_id]); end
  def user= new; @user = new; @data[:user_id] = new.id; end
  
  def project; @user ||= Project.find(:id => @data[:project_id]); end
  def project= new; @user = new; @data[:project_id] = new.id; end
end
