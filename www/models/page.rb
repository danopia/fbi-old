class Page
  attr_accessor :id, :slug
  
  def self.from_id id
    self.new Repos.filter(:id => id).first
  end
  def self.from_slug slug
    self.new Repos.filter(:slug => slug).first
  end
  
  
  def initialize data=nil
    data ||= {}
    @data = data
    @id = data[:id]
    @slug = data[:slug]
  end
  
  def project
    Project.from_id @data[:project_id]
  end
  
  def contents
    @data[:contents]
  end
  
  def title
    @data[:title]
  end
end
