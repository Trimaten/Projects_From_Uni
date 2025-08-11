class CreateQuestions < ActiveRecord::Migration[6.1]
  def change
    create_table :questions do |t|
      t.text :text
      t.string :correct_answer
      t.integer :difficulty_level
      t.references :question_pool, null: false, foreign_key: true
      t.timestamps

    end
  end
end