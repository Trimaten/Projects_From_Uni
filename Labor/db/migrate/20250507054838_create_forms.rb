class CreateForms < ActiveRecord::Migration[8.0]
  def change
    create_table :forms do |t|
      t.string :title
      t.references :stage, null: false, foreign_key: true
      # doesnt need a timestamp
      # t.timestamps
    end
  end
end