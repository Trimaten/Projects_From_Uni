class CreateQuestionPools < ActiveRecord::Migration[6.1]
  def change
    create_table :question_pools do |t|
      t.string :title
      t.text :description
      t.timestamps
    end
  end
end