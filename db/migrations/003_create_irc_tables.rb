class CreateIrcTablesMigration
  def self.run db
    db.sequel.create_table :irc_networks do |t|
      primary_key :id

      String :title, :null => false
      String :hostname, :null => false
      integer :port, :default => 6667, :null => false


      Time :last_connected

      Time :created_at, :null => false
      Time :modified_at
    end

    db.sequel.create_table :irc_channels do |t|
      primary_key :id

      foreign_key :network_id, :irc_networks, :null => false
      foreign_key :project_id, :projects

      String :name, :null => false
      boolean :catchall, :default => false

      Time :created_at, :null => false
      Time :modified_at
    end

    db.sequel.create_table :irc_project_subs do |t|
      primary_key :id

      foreign_key :channel_id, :irc_channels, :null => false
      foreign_key :project_id, :projects, :null => false

      Time :created_at, :null => false
      Time :modified_at
    end
  end
end
