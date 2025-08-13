class Workflow < ApplicationRecord
  has_many :stages, dependent: :destroy
  has_many :participants, dependent: :destroy
  belongs_to :owner, class_name: 'User'

  # Validates presence of title
  validates :title, presence: true
  # Validates status to be one of the allowed values
  validates :status, inclusion: { in: %w[draft active completed archived], message: "%{value} is not a valid status" }
  validates :description, length: { maximum: 1000 }

  scope :publicly_visible, -> { where(public: true) }

  def public?
    self.public
  end

  def private?
    !public?
  end

  # Changes status from draft to active and saves the workflow
  def start_workflow
    self.status = 'active' if status == 'draft'
    save!
  end

  # Deletes the workflow
  def delete_workflow
    destroy
  end
  # Show current stage (Debug purpose)
  def view_stage
    "Current stage: #{current_stage}"
  end
  
  # Class method to search workflows by title case-insensitively
  def self.search(query)
    if query.present?
      where("title ILIKE ?", "%#{query}%")
    else
      all
    end
  end

  # Adds a new stage with a default title and creates a form for it if none exists
  def add_stage
    new_stage_title = "Stage #{stages.count + 1}"
    stage = stages.create(title: new_stage_title)

    if stage.form.nil?
      stage.create_form!(title: "Form for #{stage.title}")
    end
    stage
  end

  # Adds a form to a specific stage if it does not already have one
  def add_form_to_stage(stage_id)
    stage = stages.find_by(id: stage_id)
    if stage && stage.form.nil?
      puts "Creating form for Stage #{stage.id}"
      stage.create_form(title: "Form Title for Stage #{stage.id}")
    else
      puts "Form already exists for Stage #{stage.id}"
    end
  end
end
