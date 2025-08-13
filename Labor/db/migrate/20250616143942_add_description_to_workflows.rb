class AddDescriptionToWorkflows < ActiveRecord::Migration[8.0]
  def change
    add_column :workflows, :description, :text
  end
end
