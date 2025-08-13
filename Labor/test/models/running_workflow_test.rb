require "test_helper"

class RunningWorkflowTest < ActiveSupport::TestCase
  def setup
    @running_workflow = running_workflows(:one)
  end

  test "should be valid with valid attributes" do
    assert @running_workflow.valid?
  end

  test "should belong to participant" do
    assert_respond_to @running_workflow, :participant
    assert_not_nil @running_workflow.participant
  end

  test "should have many running_stages" do
    assert_respond_to @running_workflow, :running_stages
  end

  test "participant_id should be unique" do
    duplicate = RunningWorkflow.new(participant: @running_workflow.participant)
    assert_not duplicate.valid?
  end

  test "after create initializes running stages" do
    user = User.create!(
      firstname: "Test",
      surname: "User",
      username: "testuser1",
      email: "testuser@example.com",
      password: "Password1!",
      password_confirmation: "Password1!"
    )
    workflow = workflows(:one)
    participant = Participant.create!(user: user, workflow: workflow, current_progress: 0)
    running_workflow = RunningWorkflow.create!(participant: participant)
    assert_equal participant.workflow.stages.count, running_workflow.running_stages.count
    assert running_workflow.running_stages.all? { |rs| rs.status == "pending" }
  end
end
