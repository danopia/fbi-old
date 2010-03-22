class InitialMigration
  def self.run db
    db.sequel.create_table :users do
      primary_key :id
      
      String :username, :unique => true, :null => false
      String :name
      String :email, :null => false
      String :website
      String :company
      String :location
      
      String :password_hash, :null => false
      String :salt, :unique => true, :null => false
      
      Time :created_at, :null => false
      Time :modified_at
    end
    
    db.sequel.create_table :user_sessions do
      primary_key :id
      
      foreign_key :user_id, :users
      
      String :ip_address
      String :cookie_token, :unique => true
      
      Time :created_at, :null => false
      Time :modified_at
    end
    

    db.sequel.create_table :services do
      primary_key :id
      
      String :title, :null => false
      String :slug, :unique => true, :null => false
      String :url_format
      String :website
      
      boolean :mirrorable, :default => false
      boolean :explorable, :default => false
      
      Time :created_at, :null => false
      Time :modified_at
    end
    
    db.sequel.create_table :projects do
      primary_key :id
      
      String :title, :null => false
      String :slug, :unique => true, :null => false
      
      boolean :use_wiki, :default => false
      boolean :use_repos, :default => false
      boolean :use_issues, :default => false
      
      Time :created_at, :null => false
      Time :modified_at
    end

    db.sequel.create_table :repos do
      primary_key :id
      
      foreign_key :project_id, :projects
      foreign_key :owner_id, :users
      foreign_key :service_id, :services
      
      String :title
      String :name
      String :slug, :null => false
      
      boolean :mirrored, :default => false
      
      Time :created_at, :null => false
      Time :modified_at
    end

    db.sequel.create_table :commits do
      primary_key :id
      
      foreign_key :repo_id, :repos
      foreign_key :author_id, :users
      
      String :hash, :null => false
      String :json, :null => false
      
      Time :created_at, :null => false
    end
  end
end
