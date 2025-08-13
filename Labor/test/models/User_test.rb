require "test_helper"

class UserTest < ActiveSupport::TestCase
  fixtures :all

  test "should not save user with special characters in the firstname" do
    user = users(:one)
    user.firstname = "Name!@HFUGUS#"
    assert_not user.save, "Saved the user with special characters in the firstname"
  end

  test "should not save user with too long firstname" do
    user = users(:two)
    user.firstname = 'a' * 129
    assert_not user.save, "Saved the user with a firstname that is too long"
  end

  test "should not save user with too short firstname" do
    user = users(:one)
    user.firstname = "A"
    assert_not user.save, "Saved the user with a firstname that is too short"
  end

  test "username should be unique" do
    user = users(:one)
    duplicate_user = users(:two).dup
    duplicate_user.username = user.username
    assert_not duplicate_user.save, "Saved the user with a duplicate username"
  end

  test "username should not contain special characters" do
    user = users(:two)
    user.username = "invalid@username"
    assert_not user.save, "Saved the user with special characters in the username"
  end

  test "username should be between 5 and 32 characters" do
    user = users(:one)
    user.username = "usr"
    assert_not user.save, "Saved the user with a too short username"

    user.username = 'a' * 33
    assert_not user.save, "Saved the user with a too long username"
  end

  test "mail address should be in mail-format" do
    user = users(:one)
    user.password = "invalid-email"
    assert_not user.save, "Saved the user with an invalid email format"
  end

  test "should not save user with too short password" do
    user = users(:two)
    user.password = "Short!"
    assert_not user.save, "Saved the user with a password that is too short"
  end

  test "should not save user without special characters in password" do
    user = users(:one)
    user.password = "NoSpecialChar123"
    assert_not user.save, "Saved the user without special characters in the password"
  end 

  test "should not save user without high-case letters in password" do
    user = users(:two)
    user.password = "nouppercase123!"
    assert_not user.save, "Saved the user without uppercase letters in the password"
  end

  test "should not save user without a digit in the password" do
    user = users(:one)
    user.password = "Password!"
    assert_not user.save, "Saved the user without a digit in the password"
  end
  test "should create and retrieve user from the database" do
    user = users(:two)
    user.firstname = "DB Test"
    user.username = "dbtestuser"
    user.email = "db@test.com"
    user.password = "Secure1!"
  
    assert user.save, "Could not save user to the database"
    fetched_user = User.find_by(id: user.id)
  
    assert_not_nil fetched_user, "User was not found in the database"
    assert_equal user.firstname, fetched_user.firstname
    assert_equal user.username, fetched_user.username
    assert_equal user.email, fetched_user.email
    puts "Fetched User ID: #{fetched_user.id}"
  end
  
  test "should find user by username using where" do
    user = users(:one)
    user.username = "whereuser"
    user.email = "where@test.com"
    user.password = "Password1!"
    assert user.save, "Failed to save user"
  
    found_user = User.where(username: "whereuser").first
    assert_not_nil found_user, "Could not find user by username"
    assert_equal user.id, found_user.id, "User IDs don't match"
  end

  test "deleting a user also deletes their filled_forms" do
    user = users(:one)
    assert user.present?, "Fixture user(:one) must exist"

    # Check that user has filled_forms
    filled_forms = FilledForm.where(user_id: user.id)
    assert_not_empty filled_forms, "User must have filled_forms"

    filled_form_ids = filled_forms.pluck(:id)

    # Destroy the user and check cascading delete
    assert_difference("User.count", -1, "User should be deleted") do
      user.destroy
    end

    # Check that each associated filled_form was deleted
    filled_form_ids.each do |id|
      assert_nil FilledForm.find_by(id: id), "FilledForm #{id} should be deleted"
    end
  end
end
