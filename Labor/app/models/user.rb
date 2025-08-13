class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
          :confirmable

  # Associations
  has_many :filled_forms, dependent: :destroy
  has_many :workflows, foreign_key: :owner_id, dependent: :destroy
  has_many :stages, dependent: :destroy
  has_many :participants, dependent: :destroy

  # Validates surname: required, 2-128 chars, no special characters
  validates :surname, presence: true, length: { in: 2..128 }, format: { without: /[^A-Za-z0-9 ]/, message: "should not contain special characters" }
  # Validates firstname: required, 2-128 chars, no special characters
  validates :firstname, presence: true, length: { in: 2..128 }, format: { without: /[^A-Za-z0-9 ]/, message: "should not contain special characters" }
  # Validates username: required, unique, 5-32 chars, no special characters
  validates :username, presence: true, uniqueness: true, length: { in: 5..32 }, format: { without: /[^A-za-z0-9]/, message: "should not contain special characters "}
  # Validates email presence and proper email format
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  # Password length must be at least 8 characters (encrypted_password handled by Devise)
  validates :encrypted_password, length: { minimum: 8 }
  # Custom validation for password complexity requirements
  validate :password_requirements

  private

  # Password must have at least one uppercase letter, one special char, and one digit
  def password_requirements
    if password.present?
      unless password =~ /[A-Z]/
        errors.add(:password, "must contain at least one uppercase letter")
      end
      unless password =~ /[^A-Za-z0-9]/
        errors.add(:password, "must contain at least one special character")
      end
      unless password.count("0-9") > 0
        errors.add(:password, "must contain at least one digit")
      end
    end
  end
end
