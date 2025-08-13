require "test_helper"

class RunningStageTest < ActiveSupport::TestCase
  def setup
    @running_stage = running_stages(:one)
  end

  test "should be valid with valid attributes" do
    assert @running_stage.valid?
  end

  test "status should be in allowed statuses" do
    @running_stage.status = "in_progress"
    assert @running_stage.valid?

    @running_stage.status = "invalid_status"
    assert_not @running_stage.valid?
  end

  test "should belong to running_workflow" do
    assert_respond_to @running_stage, :running_workflow
    assert_not_nil @running_stage.running_workflow
  end

  test "should belong to stage" do
    assert_respond_to @running_stage, :stage
    assert_not_nil @running_stage.stage
  end

  test "to_s returns correct string" do
    expected = "#{@running_stage.stage.title} - #{@running_stage.status}"
    assert_equal expected, @running_stage.to_s
  end
end
