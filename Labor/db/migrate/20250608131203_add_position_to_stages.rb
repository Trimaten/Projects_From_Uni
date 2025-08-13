class AddPositionToStages < ActiveRecord::Migration[8.0]
  def change
    add_column :stages, :position, :integer
  end
end
