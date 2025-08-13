class SearchController < ApplicationController
  # Displays the search page with a banner title
  def index
    @banner_title = "Search"
  end

  # Processes the search query submitted by the user
  def search
    @banner_title = "Search"

    # Check if the search query is present
    if params[:query].present?
      @workflow_search_results = Workflow.publicly_visible.or(Workflow.where(owner_id: current_user.id)).distinct.search(params[:query])
    else
      @workflow_search_results = Workflow.publicly_visible.or(Workflow.where(owner_id: current_user.id)).distinct
    end

    # Render the search results page
    render :search
  end

end
