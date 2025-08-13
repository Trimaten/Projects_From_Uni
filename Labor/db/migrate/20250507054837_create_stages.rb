class CreateStages < ActiveRecord::Migration[8.0]
  def change
    create_table :stages do |t|
      t.string :title
      t.references :user, foreign_key: true, null: true
      # t.timestamps
    end
  end
end
