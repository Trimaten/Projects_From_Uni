class AddCascadeDeleteToUserForeignKeys < ActiveRecord::Migration[8.0]
  def change
    # filled_forms.user_id
    remove_foreign_key :filled_forms, :users
    add_foreign_key :filled_forms, :users, on_delete: :cascade

    # participants.user_id
    remove_foreign_key :participants, :users
    add_foreign_key :participants, :users, on_delete: :cascade

    # stages.user_id
    remove_foreign_key :stages, :users
    add_foreign_key :stages, :users, on_delete: :cascade

    # workflows.owner_id
    remove_foreign_key :workflows, column: :owner_id
    add_foreign_key :workflows, :users, column: :owner_id, on_delete: :cascade
  end
end
