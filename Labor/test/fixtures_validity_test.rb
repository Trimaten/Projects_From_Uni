require "test_helper"

class FixturesValidityTest < ActiveSupport::TestCase
  test "all fixtures are valid" do
    ActiveRecord::Base.descendants.each do |model|
      next if model.abstract_class?
      next unless model.table_exists?
      next if model.name.start_with?("ActiveStorage::") # skip Rails internals

      begin
        model.all.each do |record|
          assert record.valid?, "#{model.name} fixture invalid: #{record.errors.full_messages.join(", ")}"
        end
      rescue => e
        flunk "Error loading #{model.name} fixtures: #{e.message}"
      end
    end
  end
end
