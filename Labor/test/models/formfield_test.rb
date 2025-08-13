require "test_helper"

class FormfieldTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @workflow = workflows(:one)
    @stage = stages(:first_stage)
    @form = forms(:first_form)
  end

  test "validates presence of variableName" do
    formfield = Formfield.new(title: "Test Title", content: "Test Content", form: @form, typefield: :text)
    assert formfield.valid?, "Formfield should be valid even without variableName"
  end

  test "validates presence of title" do
    formfield = Formfield.new(variableName: "Test Variable", content: "Test Content", form: @form, typefield: :text)
    assert_not formfield.valid?
    assert_includes formfield.errors[:title], "can't be blank"
  end

  test "validates presence of form_id" do
    formfield = Formfield.new(variableName: "Test Variable", title: "Test Title", content: "Test Content", typefield: :text)
    assert_not formfield.valid?
    assert_includes formfield.errors[:form], "must exist"
  end

  test "validates presence of typefield" do
    formfield = Formfield.new(typefield: nil)
    assert_not formfield.valid?
    assert_includes formfield.errors[:typefield], "can't be blank"
  end

  test "validates length of variableName" do
    formfield = Formfield.new(variableName: "a" * 129, title: "Test Title", content: "Test Content", form: @form, typefield: :text)
    assert_not formfield.valid?
    assert_includes formfield.errors[:variableName], "is too long (maximum is 128 characters)"
  end

  test "validates length of title" do
    formfield = Formfield.new(variableName: "Test Variable", title: "a" * 129, content: "Test Content", form: @form, typefield: :text)
    assert_not formfield.valid?
    assert_includes formfield.errors[:title], "is too long (maximum is 128 characters)"
  end

  test "validates format of variableName" do
    formfield = Formfield.new(variableName: "Invalid@Variable", title: "Test Title", content: "Test Content", form: @form, typefield: :text)
    assert formfield.valid?
  end

  test "validates format of title" do
    formfield = Formfield.new(variableName: "Test Variable", title: "Invalid@Title", content: "Test Content", form: @form, typefield: :text)
    assert formfield.valid?
  end

  test "validates format of content" do
    formfield = Formfield.new(variableName: "Test Variable", title: "Test Title", content: "Invalid@Content", form: @form, typefield: :text)
    assert formfield.valid?
  end

  test "validates numericality of form_id" do
    formfield = Formfield.new(variableName: "Test Variable", title: "Test Title", content: "Test Content", form_id: -1, typefield: :text)
    assert_not formfield.valid?
  end

  test "Creates a formfield with valid attributes" do
    formfield = Formfield.new(variableName: "Test Variable", title: "Test Title", content: "Test Content", form: @form, typefield: :text)
    assert formfield.valid?
    assert formfield.save, "Formfield should be saved successfully"
  end

  test "Associates form should include formfield" do
    formfield = Formfield.create!(variableName: "Test Variable", title: "Test Title", content: "Test Content", form: @form, typefield: :text)
    assert_equal @form, formfield.form, "Formfield should be associated with the correct form"
  end
end
