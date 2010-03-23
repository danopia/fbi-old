class CreateProjectMembersMigration
  def self.run db
    db.sequel.create_table :project_members do
      primary_key :id
      
      foreign_key :user_id, :users
      foreign_key :project_id, :projects
      
      boolean :owner, :default => false
      
      Time :created_at, :null => false
      Time :modified_at
    end
  end
end
