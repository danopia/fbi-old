require 'rubygems'
require 'sequel'
require 'json'

module FBI
class Database
  attr_reader :sequel
  attr_accessor :filename
  
  def initialize filename='sqlite.db'
    @sequel = Sequel.sqlite filename
    
    migrate
  end
  
  def [] table
    @sequel[table]
  end
  
  def migrate
    create_migrations_table unless @sequel.table_exists? :migrations
    table = self[:migrations]
    
    migrated = table.all.map {|row| row[:name] }
    
    migration_path = File.join(File.dirname(__FILE__), 'migrations')
    migration_files = Dir.entries migration_path
    migration_files.sort.each {|file|
      next if file[0,1] == '.'
      
      require File.join(migration_path, file)
      basename = file.match(/^[0-9]+_(.+)\.rb$/).captures.first
      next if migrated.include? basename
      
      classname = basename.gsub(/_[a-z]/) {|m| m[1,1].upcase }
      classname = "#{classname.capitalize}Migration"
      klass = Class.const_get(classname)
      
      print "Migrating #{basename}... "
      STDOUT.flush
      
      klass.run self
      table << {:name => basename, :created_at => Time.now}
      
      puts 'done.'
    }
  end
  
  def create_migrations_table
    @sequel.create_table :migrations do
      primary_key :id
      String :name, :unique => true, :null => false
      Time :created_at, :null => false
    end
  end
end
end
