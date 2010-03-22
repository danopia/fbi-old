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
  end
end
