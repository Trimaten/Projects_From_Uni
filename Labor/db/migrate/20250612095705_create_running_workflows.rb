class CreateRunningWorkflows < ActiveRecord::Migration[8.0]
  def change
    create_table :running_workflows do |t|
      t.references :participant, null: false, foreign_key: true

      t.timestamps
    end
  end
end
