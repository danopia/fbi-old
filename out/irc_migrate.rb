require 'irc_models'

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
			end

			si = SchemaInfo.find(:first) || SchemaInfo.new(:version => opts[:assume])
			
			if si.version < opts[:version]
				@migrations.each do |k|
					k.migrate(:up) if si.version < k.version and k.version <= opts[:version]
					k.migrate(:down) if si.version > k.version and k.version > opts[:version]
				end
				puts "Version to go to: #{opts[:version]}"
				puts "Assumed version: #{opts[:assume]}"
			end

			si.update_attributes(:version => opts[:version])
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
		puts "Migrations: #{@migrations.to_a.join(', ')}"
		puts "Final Version: #{@final.to_i}"
		puts "Migration version: #{@migrations[0].version}"
	end
end

class CreateProjects < Migration::V(1)
	def self.up
		create_table :projects do |t|
			t.string :name
			
			t.timestamps
		end
	end
	def self.down
		drop_table :projects
	end
end

class CreateServers < Migration::V(2)
	def self.up
		create_table :servers do |t|
			t.string :hostname
			t.integer :port
			
			t.timestamps
		end
	end
	def self.down
		drop_table :servers
	end
end

class CreateChannels < Migration::V(3)
	def self.up
		create_table :channels do |t|
			t.references :server
			
			t.string :name
			t.boolean :catchall, :default => false
			
			t.timestamps
		end
	end
	def self.down
		drop_table :channels
	end
end
 
class CreateProjectSubs < Migration::V(4)
	def self.up
		create_table :project_subs do |t|
			t.references :project
			t.references :channel
			
			t.timestamps
		end
	end
	def self.down
		drop_table :project_subs
	end
end

class AddDefaultProjectToChannel < Migration::V(5)
	def self.up
		add_column :channels, :default_project, :string
	end
	def self.down
		remove_column :channels, :default_project
	end
end

Migration::debug
Migration::create_schema
