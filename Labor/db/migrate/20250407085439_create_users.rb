class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    unless table_exists?(:users)
      create_table :users do |t|
        t.string :surname
        t.string :firstname
        t.string :username
        t.string :email

      # t.timestamps # Adds created_at and updated_at columns
      end
    end
  end
end
