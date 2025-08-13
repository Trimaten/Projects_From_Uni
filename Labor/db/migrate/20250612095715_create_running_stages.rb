class CreateRunningStages < ActiveRecord::Migration[8.0]
  def change
    create_table :running_stages do |t|
      t.references :running_workflow, null: false, foreign_key: true
      t.references :stage, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"

      t.timestamps
    end
  end
end
