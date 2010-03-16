class Renderer < Mustache
  def self.render file, context
    #p self.public_methods-Class.public_methods
    super File.read("#{Mustache.template_path}/#{file}.#{template_extension}"), context
  end
end
