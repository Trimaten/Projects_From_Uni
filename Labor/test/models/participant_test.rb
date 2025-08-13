require "test_helper"

class ParticipantTest < ActiveSupport::TestCase
  fixtures :users, :workflows, :participants

  def setup
    @user = users(:one)
    @workflow = workflows(:one)
    @participant_one = participants(:one)
    @participant_two = participants(:two)
  end

  test "should create participant workflow with valid attributes" do
    new_user = users(:two)
    new_workflow = workflows(:two)
    participant_workflow = Participant.new(user: new_user, workflow: new_workflow, current_progress: 0)
    assert participant_workflow.valid?
    assert participant_workflow.save
  end

  test "should not create participant workflow without user" do
    participant_workflow = Participant.new(workflow: @workflow, current_progress: 0)
    assert_not participant_workflow.valid?
    assert_includes participant_workflow.errors[:user], "must exist"
  end

  test "should not create participant workflow without workflow" do
    participant_workflow = Participant.new(user: @user, current_progress: 0)
    assert_not participant_workflow.valid?
    assert_includes participant_workflow.errors[:workflow], "must exist"
  end

  test "should not create participant workflow with negative progress" do
    participant_workflow = Participant.new(user: users(:two), workflow: workflows(:two), current_progress: -1)
    assert_not participant_workflow.valid?
    assert_includes participant_workflow.errors[:current_progress], "must be greater than or equal to 0"
  end

  test "should not create participant workflow with non-integer progress" do
    participant_workflow = Participant.new(user: users(:two), workflow: workflows(:two), current_progress: 0.5)
    assert_not participant_workflow.valid?
    assert_includes participant_workflow.errors[:current_progress], "must be an integer"
  end

  test "should update progress" do
    @participant_one.update_progress(50)
    assert_equal 50, @participant_one.current_progress
  end

  test "should remove participant workflow" do
    @participant_two.running_workflow.destroy
    assert_difference('Participant.count', -1) do
      @participant_two.remove_participant
    end
  end

  test "should view participant workflow details" do
    expected_view = "Participant ID: #{@participant_one.user.id}, Workflow ID: #{@participant_one.workflow.id}, Current Progress: #{@participant_one.current_progress}"
    assert_equal expected_view, @participant_one.view_participant_workflow
  end

  test "should not allow duplicate user in the same workflow" do
    duplicate_participant = Participant.new(user: @user, workflow: @workflow, current_progress: 0)
    assert_not duplicate_participant.valid?
    assert_includes duplicate_participant.errors[:user_id], "User already assigned to this workflow"
  end
end
