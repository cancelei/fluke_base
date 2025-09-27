class UpdateExistingProjectsPublicFields < ActiveRecord::Migration[8.0]
  def up
    # Update existing projects to have essential fields public by default
    # This improves project discovery in the explore section
    default_public_fields = %w[name description stage collaboration_type category funding_status team_size]

    Project.find_each do |project|
      # Only update projects that have empty public_fields
      if project.public_fields.blank?
        project.update_column(:public_fields, default_public_fields)
      end
    end
  end

  def down
    # Revert to empty public_fields for projects that had them empty
    # This is a conservative approach - we only revert projects that likely had
    # the default empty array before this migration
    Project.where(public_fields: %w[name description stage collaboration_type category funding_status team_size]).find_each do |project|
      project.update_column(:public_fields, [])
    end
  end
end
