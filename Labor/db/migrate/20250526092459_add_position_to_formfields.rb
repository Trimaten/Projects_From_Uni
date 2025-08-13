class AddPositionToFormfields < ActiveRecord::Migration[8.0]
  def change
    add_column :formfields, :position, :integer
  end
end
