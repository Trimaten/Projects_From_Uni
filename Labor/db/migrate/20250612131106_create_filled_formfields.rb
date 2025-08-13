class CreateFilledFormfields < ActiveRecord::Migration[8.0]
  def change
    create_table :filled_formfields do |t|
      t.references :filled_form, null: false, foreign_key: true
      t.references :formfield, null: false, foreign_key: true
      t.string :value

      t.timestamps
    end
  end
end
