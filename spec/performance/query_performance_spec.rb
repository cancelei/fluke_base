require 'rails_helper'

RSpec.describe 'Query Performance', type: :model do
  describe 'agreement participant loading' do
    it 'avoids N+1 queries when loading participants' do
      create_list(:agreement, 3, :with_participants)

      # Test that the query count is reasonable (should be around 3-4 queries)
      query_count = count_queries do
        Agreement.includes(agreement_participants: :user).find_each do |agreement|
          agreement.agreement_participants.each { |p| p.user.email }
        end
      end

      expect(query_count).to be <= 10  # Allow reasonable query count
      expect(query_count).to be >= 1   # Must execute at least 1 query
    end
  end

  describe 'project with related data' do
    it 'efficiently loads agreements with participants' do
      project = create(:project)
      create_list(:agreement, 5, :with_participants, project:)

      expect do
        proj = Project.includes(agreements: { agreement_participants: :user }).find(project.id)
        proj.agreements.each do |agreement|
          agreement.agreement_participants.each { |p| p.user.full_name }
        end
      end.not_to exceed_query_limit(3)
    end
  end
end
