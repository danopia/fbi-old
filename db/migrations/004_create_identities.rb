class CreateIdentitiesMigration
  def self.run db
    db.sequel.create_table :identities do
      primary_key :id
      
      foreign_key :user_id, :users, :null => false
      foreign_key :service_id, :services
      
      String :key, :null => false
      String :json, :null => true
      
      Time :created_at, :null => false
      Time :modified_at
    end
  end
end
