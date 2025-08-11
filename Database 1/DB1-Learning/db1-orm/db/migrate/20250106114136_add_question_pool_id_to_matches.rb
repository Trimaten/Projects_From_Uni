class AddQuestionPoolIdToMatches < ActiveRecord::Migration[6.1]
  def change
    add_reference :matches, :question_pool, foreign_key: true
    add_column :matches, :rounds_count, :integer
  end
end