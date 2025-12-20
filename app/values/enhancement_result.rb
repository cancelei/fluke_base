# frozen_string_literal: true

# Value object for AI enhancement results (not saved to DB)
# Used when enhancing milestones directly without creating a MilestoneEnhancement record
EnhancementResult = Data.define(
  :id,
  :original_title,
  :original_description,
  :enhanced_description,
  :enhancement_style,
  :status,
  :successful,
  :direct_enhancement,
  :created_at,
  :user
) do
  def successful? = successful
end
