require 'rubygems'
require 'active_record'

ActiveRecord::Base.establish_connection({
		:adapter => 'sqlite3',
		:dbfile => 'db/database-new.sqlite3'
		})

class Object #:nodoc:
	def meta_def(m,&b) #:nodoc:
		(class<<self;self end).send(:define_method,m,&b)
	end
end

class Migration
	class SchemaInfo < ActiveRecord::Base
		# Nothing...
	end

	def self.create_schema(opts = {})
		opts[:assume] ||= 0
		opts[:version] ||= @final

		if @migrations
			unless SchemaInfo.table_exists?
				ActiveRecord::Schema.define do
					create_table SchemaInfo.table_name do |t|
						t.float :version
					end
				end

				si = SchemaInfo.find(:first) || SchemaInfo.new(:version => opts[:assume])
				
				if si.version < opts[:version]
					@migrations.each do |k|
						k.migrate(:up) if si.version < k.version and k.version <= opts[:version]
						k.migrate(:down) if si.version > k.version and k.version > opts[:version]
					end
					puts "Version to go to: "
					puts opts[:version]
					puts "Assumed version: "
					puts opts[:assume]
				end

				si.update_attributes(:version => opts[:version])
			end
		end
	end
	def self.V(n)
		@final = [n, @final.to_i].max
		m = (@migrations ||= [])
		Class.new(ActiveRecord::Migration) do
			meta_def(:version) { n }
			meta_def(:inherited) { |k| m << k }
		end
	end

	def self.debug
		puts "Migrations: "
		puts @migrations.to_a
		puts "Final Version: "
		puts @final.to_i
		puts "Migration version: "
		puts @migrations[0].version
	end
	
end

class CreateFactoids < Migration::V(1.0)
	def up
		create_table :factoids do |t|
			t.string :key
			t.string :value
			t.timestamps
		end
	end
	def down

	end
end

Migration::debug
Migration::create_schema
