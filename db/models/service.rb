class Service < FBI::Model

  def title; @data[:title]; end
  def slug; @data[:slug]; end
  def url_format; @data[:url_format]; end
  def website; @data[:website]; end
  
  def mirrorable?; @data[:mirrorable]; end
  def explorable?; @data[:explorable]; end
  
  
  def title= new; @data[:title] = new; end
  def slug= new; @data[:slug] = new; end
  def url_format= new; @data[:url_format] = new; end
  def website= new; @data[:website] = new; end
  
  def mirrorable= new; @data[:mirrorable] = new; end
  def explorable= new; @data[:explorable] = new; end
  
  
  def repos
    Repo.where :service_id => @id
  end
  
  def show_path; "/services/#{slug}"; end
  def edit_path; "#{show_path}/edit"; end
  
  def show_link; "<a href=\"#{show_path}\">#{title}</a>"; end
end
