class Identity < FBI::Model
  table :identities

  def key; @data[:key]; end
  def json; JSON.parse @data[:json] rescue {}; end
  def raw_json; @data[:json].to_json; end
  def service_id; @data[:service_id]; end
  def user_id; @data[:user_id]; end
  
  def key= new; @data[:key] = new; end
  def json= new; @data[:json] = new.to_json; end
  def service_id= new; @data[:service_id] = new; end
  def user_id= new; @data[:user_id] = new; end

  def user; @user ||= User.find(:id => @data[:user_id]); end
  def user= new; @user = new; @data[:user_id] = new.id; end

  def service; @service ||= Service.find(:id => @data[:service_id]); end
  def service= new; @service = new; @data[:service_id] = new.id; end
  
  
  def show_path; "/account/identities/#{id}"; end
  def edit_path; "#{show_path}/edit"; end
  def user_path; user.profile_path; end
  def service_path; service.show_path; end
  
  def show_link; "<a href=\"#{show_path}\">#{service.title}: #{key}</a>"; end
  def user_link; user.profile_link; end
  def service_link; service.show_link; end
end
