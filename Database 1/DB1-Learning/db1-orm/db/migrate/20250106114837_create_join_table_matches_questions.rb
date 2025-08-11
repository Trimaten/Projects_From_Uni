class CreateJoinTableMatchesQuestions < ActiveRecord::Migration[6.1]
  def change
    create_join_table :matches, :questions do |t|
      t.index [:match_id, :question_id]
      t.index [:question_id, :match_id]
    end
  end
end