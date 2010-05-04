class BetterCommitsMigration
  def self.run db
    db.sequel.drop_table :commits
    db.sequel.create_table :commits do
      primary_key :id
      
      foreign_key :repo_id, :repos
      foreign_key :author_id, :user
      foreign_key :identity_id, :identities
      
      String :message, :null => false
      String :hash, :null => false
      String :json, :null => false
      
      Time :commited_at, :null => false
      Time :created_at, :null => false
      Time :modified_at
    end
  end
end
