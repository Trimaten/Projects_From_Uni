class AddApprovedToFilledForms < ActiveRecord::Migration[8.0]
  def change
    add_column :filled_forms, :approved, :boolean, default: false, null: false
  end
end
