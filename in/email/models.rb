# connect to the database
ActiveRecord::Base.establish_connection({
      :adapter => "sqlite3", 
      :dbfile => "db/database.sqlite3"
})

class Factoid < ActiveRecord::Base
  validates_uniqueness_of :key
end
