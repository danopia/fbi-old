require File.join(File.dirname(__FILE__), 'model')

Dir.glob(File.join(File.dirname(__FILE__), '..', 'db', 'models', '*.rb')).each do |model|
  require model
end
