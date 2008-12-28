# require AR
require 'rubygems'
require 'active_record'

# connect to the database (sqlite in this case)
ActiveRecord::Base.establish_connection({
      :adapter => "sqlite3", 
      :dbfile => "db/database.sqlite3"
})


# define a migration
class CreateFactoids < ActiveRecord::Migration
  def self.up
    create_table :factoids do |t|
      t.string :key
      t.string :value
      t.string :creator
      t.timestamps
    end
  end

  def self.down
    drop_table :factoids
  end
end

# run the migration
CreateFactoids.migrate(:up)
