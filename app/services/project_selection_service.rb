class ProjectSelectionService
  def initialize(user, session, project_id)
    @user = user
    @session = session
    @project_id = project_id
  end

  def call
    return false unless project

    update_user_selection
    update_session
    true
  end

  def project
    @project ||= Project.find_by(id: @project_id)
  end

  private

  def update_user_selection
    if @user.current_role_id == 2 # Mentor
      @user.update(selected_project_id: project.id, current_role_id: 1)
    else
      @user.update(selected_project_id: project.id)
    end
  end

  def update_session
    @session[:selected_project_id] = project.id
  end
end
