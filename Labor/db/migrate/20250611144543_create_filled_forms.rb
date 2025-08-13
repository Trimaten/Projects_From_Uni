class CreateFilledForms < ActiveRecord::Migration[8.0]
  def change
    create_table :filled_forms do |t|
      t.references :form, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      
      t.timestamps
    end
  end
end
