class AddFormReferenceToFormfields < ActiveRecord::Migration[8.0]
  def change
    unless column_exists?(:formfields, :form_id)
      add_reference :formfields, :form, foreign_key: true, index: true
    end
  end
end
