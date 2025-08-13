class CreateWorkflows < ActiveRecord::Migration[8.0]
  def change
    create_table :workflows do |t|
      t.string :title
      t.string :status
      t.references :owner, null: false, foreign_key: { to_table: :users }
      t.integer :current_stage, default: 0
      end

      create_table :participants do |t|
      t.references :workflow, null: false, foreign_key: true
      t.integer :current_progress, default: 0
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
  end
end
