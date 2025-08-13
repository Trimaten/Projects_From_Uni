class AddApprovableToStages < ActiveRecord::Migration[8.0]
  def change
    add_column :stages, :approvable, :boolean, default: false, null: false
  end
end
