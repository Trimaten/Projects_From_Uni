require "test_helper"

class FormTest < ActiveSupport::TestCase
  fixtures :users, :workflows, :stages, :forms

  def setup
    @stage = stages(:first_stage)
  end

  test "validates presence of title" do
    form = Form.new(title: nil, stage: @stage)
    assert_not form.valid?
    assert_includes form.errors[:title], "can't be blank"
  end

  test "Creates a form with valid attributes" do
    form = Form.new(title: "Test Form", stage: @stage)
    assert form.valid?
    assert form.save, "Form should be saved successfully"
    puts "Form ID: #{form.id}"
    assert_equal "Test Form", form.title, "Form title should be 'Test Form'"
  end

  test "Associates stage should include form" do
    form = Form.create!(title: "Test Form", stage: @stage)
    assert_equal form, @stage.form, "Stage should be associated with the correct form"
  end

  test "Title length validation" do
    form = Form.new(title: "a" * 129, stage: @stage)
    assert_not form.valid?
    assert_includes form.errors[:title], "is too long (maximum is 128 characters)"
  end

  test "Title format validation" do
    form = Form.new(title: "Valid Title!@#", stage: @stage)
    assert form.valid?, "Form should be valid with special characters in title"
    assert form.save, "Form should be saved successfully"
    assert_equal "Valid Title!@#", form.title, "Form title should be 'Valid Title!@#'"
  end

  test "Creating Form with 2 FormFields" do
    form = Form.create!(title: "Test Form", stage: @stage)

    field1 = form.form_fields.create!(
      variableName: "Field1",
      title: "Field 1",
      content: "Sample content",
      typefield: :text
    )

    field2 = form.form_fields.create!(
      variableName: "Field2",
      title: "Field 2",
      content: "Sample content",
      typefield: :number
    )

    assert form.form_fields.include?(field1), "Form should include Field 1"
    assert form.form_fields.include?(field2), "Form should include Field 2"
    assert_equal 2, form.form_fields.count, "Form should have 2 form fields"

    puts "Form ID: #{form.id}"
    puts "Form Field1 ID: #{form.form_fields.first.id}"
    puts "Field 1 ID: #{field1.id}"
    puts "Field 2 ID: #{field2.id}"
    puts "Form 1 typefield: #{field1.typefield}"
  end
end
