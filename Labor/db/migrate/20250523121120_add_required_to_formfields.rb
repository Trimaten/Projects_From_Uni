class AddRequiredToFormfields < ActiveRecord::Migration[8.0]
  def change
    add_column :formfields, :required, :boolean
  end
end
