class UserAccountsController < ApplicationController
  # Ensure only logged-in users can access actions
  before_action :authenticate_user!

  def destroy
    user = current_user

    # Sign out the user before destroying the account
    sign_out user
    
    if user.destroy
      redirect_to unauthenticated_root_path, notice: "Your account has been successfully deleted."
    else
      # Handle unlikely failure (e.g., DB constraint issues)
      redirect_to edit_user_registration_path, alert: "We couldn't delete your account. Please try again later."
    end
  end
end
