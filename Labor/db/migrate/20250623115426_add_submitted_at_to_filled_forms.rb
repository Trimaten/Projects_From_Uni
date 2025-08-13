class AddSubmittedAtToFilledForms < ActiveRecord::Migration[8.0]
  def change
    add_column :filled_forms, :submitted_at, :datetime
  end
end
