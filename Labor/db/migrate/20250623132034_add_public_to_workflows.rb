class AddPublicToWorkflows < ActiveRecord::Migration[7.0]
  def change
    add_column :workflows, :public, :boolean, default: false, null: false
  end
end
