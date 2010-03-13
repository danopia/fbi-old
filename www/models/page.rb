require 'bluecloth'

class Page
  attr_accessor :id, :slug, :contents, :title
  
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
    @contents = data[:contents]
    @title = data[:title]
    @slug = data[:slug]
  end
  
  def project
    Project.from_id @data[:project_id]
  end
  
  def render
    BlueCloth.new(@contents).to_html
  end
end
