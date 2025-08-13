class CreateFormFields < ActiveRecord::Migration[8.0]
  def change
    create_table :formfields do |t|
      t.integer :typefield, default: 0 # Changed from :type to :typefield to avoid conflict with Ruby's built-in type method
      t.string :variableName
      t.text :content # This can store different types of input as needed
      t.string :title
      t.references :form, null: false, foreign_key: true

      # t.timestamps
    end
  end
end