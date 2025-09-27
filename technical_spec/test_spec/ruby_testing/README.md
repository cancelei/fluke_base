# Ruby Testing Patterns in FlukeBase

This document outlines comprehensive testing patterns for Ruby code, complementing the implementation patterns documented in `../ruby_patterns/README.md`.

## Table of Contents

1. [Testing Framework Setup](#testing-framework-setup)
2. [Model Testing Patterns](#model-testing-patterns)
3. [Form Object Testing](#form-object-testing)
4. [Service Object Testing](#service-object-testing)
5. [Controller Testing Patterns](#controller-testing-patterns)
6. [Integration Testing](#integration-testing)
7. [Test Data Management](#test-data-management)
8. [Performance Testing](#performance-testing)

## Testing Framework Setup

### RSpec Configuration
**Files**: `spec/rails_helper.rb`, `spec/spec_helper.rb`

FlukeBase uses RSpec as the primary testing framework with the following key gems:
- **RSpec Rails** - Rails-specific RSpec functionality
- **Shoulda Matchers** - Rails-specific matchers for validations/associations
- **FactoryBot** - Test data generation
- **Capybara** - Integration testing
- **Database Cleaner** - Test database management

### Current Test Structure
```
spec/
├── models/           # Model unit tests
├── forms/           # Form object tests  
├── services/        # Service object tests
├── controllers/     # Controller unit tests
├── requests/        # Integration/API tests
├── views/          # View template tests
├── helpers/        # Helper method tests
├── jobs/           # Background job tests
└── e2e/            # End-to-end tests (Playwright)
```

## Model Testing Patterns

### Comprehensive Model Testing
**File**: `spec/models/agreement_spec.rb:1-349`

Our model tests follow a structured pattern covering all aspects of the model:

#### 1. Association Testing
```ruby
describe "associations" do
  it { should belong_to(:project) }
  it { should have_many(:agreement_participants).dependent(:destroy) }
  it { should have_many(:users).through(:agreement_participants) }
  it { should have_many(:meetings).dependent(:destroy) }
  it { should have_many(:github_logs).dependent(:destroy) }
end
```

#### 2. Validation Testing with Context
```ruby
describe "validations" do
  subject { create(:agreement, :with_participants, :mentorship, project: project, initiator: alice, other_party: bob) }

  it { should validate_presence_of(:project_id) }
  it { should validate_presence_of(:payment_type) }
  it { should validate_inclusion_of(:status).in_array([
    Agreement::PENDING, Agreement::ACCEPTED, Agreement::REJECTED,
    Agreement::COMPLETED, Agreement::CANCELLED, Agreement::COUNTERED
  ]) }

  context "when payment type is hourly" do
    subject { build(:agreement, payment_type: Agreement::HOURLY) }
    it { should validate_presence_of(:hourly_rate) }
    it { should validate_numericality_of(:hourly_rate).is_greater_than_or_equal_to(0) }
  end
end
```

#### 3. Custom Validation Testing
```ruby
describe "end_date_after_start_date" do
  it "is valid when end date is after start date" do
    agreement = build(:agreement, :co_founder,
      project: project,
      start_date: 1.week.from_now,
      end_date: 2.weeks.from_now
    )
    expect(agreement).to be_valid
  end

  it "is invalid when end date is before start date" do
    agreement = build(:agreement, :co_founder,
      project: project,
      start_date: 2.weeks.from_now,
      end_date: 1.week.from_now
    )
    expect(agreement).not_to be_valid
    expect(agreement.errors[:end_date]).to include("must be after the start date")
  end
end
```

#### 4. Scope Testing
```ruby
describe "scopes" do
  let!(:mentorship) { create(:agreement, :mentorship) }
  let!(:co_founder) { create(:agreement, :co_founder) }
  let!(:pending_agreement) { create(:agreement, :co_founder, status: Agreement::PENDING) }
  let!(:accepted_agreement) { create(:agreement, :co_founder, :accepted) }

  it "filters by agreement type" do
    expect(Agreement.mentorships).to include(mentorship)
    expect(Agreement.mentorships).not_to include(co_founder)
    expect(Agreement.co_founding).to include(co_founder)
    expect(Agreement.co_founding).not_to include(mentorship)
  end

  it "filters by status" do
    expect(Agreement.pending).to include(pending_agreement)
    expect(Agreement.pending).not_to include(accepted_agreement)
    expect(Agreement.active).to include(accepted_agreement)
    expect(Agreement.active).not_to include(pending_agreement)
  end
end
```

#### 5. Business Logic Testing
```ruby
describe "status transitions" do
  let(:agreement) { create(:agreement, :with_participants, :mentorship, project: project, initiator: alice, other_party: bob) }

  describe "#accept!" do
    it "transitions from pending to accepted" do
      expect(agreement.status).to eq(Agreement::PENDING)
      result = agreement.accept!
      expect(result).to be_truthy
      expect(agreement.reload.status).to eq(Agreement::ACCEPTED)
    end

    it "fails when not pending" do
      agreement.update!(status: Agreement::ACCEPTED)
      result = agreement.accept!
      expect(result).to be_falsey
    end
  end
end
```

#### 6. Complex Method Testing
```ruby
describe "participant methods" do
  let(:agreement) { create(:agreement, :with_participants, :mentorship, project: project, initiator: alice, other_party: bob) }

  it "identifies the initiator" do
    expect(agreement.initiator).to eq(alice)
    expect(agreement.initiator_id).to eq(alice.id)
  end

  it "provides all participants" do
    participants = agreement.participants
    expect(participants.count).to eq(2)
    expect(participants.map(&:user)).to contain_exactly(alice, bob)
  end
end
```

### Testing Patterns for Service Object Integration
**Reference**: `../ruby_patterns/README.md` - Service Object Pattern

When models delegate to service objects, test both the delegation and the service:

```ruby
describe "service delegation" do
  it "delegates avatar_url to AvatarService" do
    user = create(:user)
    service_double = double("AvatarService", url: "http://example.com/avatar.jpg")
    allow(AvatarService).to receive(:new).with(user).and_return(service_double)
    
    expect(user.avatar_url).to eq("http://example.com/avatar.jpg")
    expect(AvatarService).to have_received(:new).with(user)
  end
end
```

## Form Object Testing

### Comprehensive Form Object Testing
**File**: `spec/forms/agreement_form_spec.rb:1-333`

Form objects require testing of validation, business logic, and persistence:

#### 1. Form Validation Testing
```ruby
describe "validations" do
  subject { AgreementForm.new(valid_attributes) }

  it { should validate_presence_of(:project_id) }
  it { should validate_presence_of(:initiator_user_id) }
  it { should validate_presence_of(:other_party_user_id) }
  it { should validate_numericality_of(:weekly_hours).is_greater_than(0).is_less_than_or_equal_to(40) }

  context "when payment type is hourly" do
    subject { AgreementForm.new(valid_attributes.merge(payment_type: Agreement::HOURLY)) }
    it { should validate_presence_of(:hourly_rate) }
    it { should validate_numericality_of(:hourly_rate).is_greater_than_or_equal_to(0) }
  end
end
```

#### 2. Complex Data Handling Testing
```ruby
describe "milestone handling" do
  describe "#milestone_ids_array" do
    it "parses comma-separated string" do
      form = AgreementForm.new(milestone_ids: "#{milestone1.id},#{milestone2.id}")
      expect(form.milestone_ids_array).to contain_exactly(milestone1.id, milestone2.id)
    end

    it "handles array input" do
      form = AgreementForm.new(milestone_ids: [milestone1.id, milestone2.id])
      expect(form.milestone_ids_array).to contain_exactly(milestone1.id, milestone2.id)
    end

    it "handles JSON string" do
      json_string = [milestone1.id, milestone2.id].to_json
      form = AgreementForm.new(milestone_ids: json_string)
      expect(form.milestone_ids_array).to contain_exactly(milestone1.id, milestone2.id)
    end

    it "filters out zero values" do
      form = AgreementForm.new(milestone_ids: "#{milestone1.id},0,#{milestone2.id}")
      expect(form.milestone_ids_array).to contain_exactly(milestone1.id, milestone2.id)
    end
  end
end
```

#### 3. Business Logic Testing
```ruby
describe "save and create" do
  it "creates agreement with participants" do
    form = AgreementForm.new(valid_attributes)

    expect {
      expect(form.save).to be true
    }.to change(Agreement, :count).by(1)
      .and change(AgreementParticipant, :count).by(2)

    agreement = form.agreement
    expect(agreement.project).to eq(project)
    expect(agreement.initiator).to eq(alice)
    expect(agreement.other_party).to eq(bob)
    expect(agreement.milestone_ids).to contain_exactly(milestone1.id, milestone2.id)

    # Check participants
    initiator_participant = agreement.agreement_participants.find_by(is_initiator: true)
    expect(initiator_participant.user).to eq(alice)
    expect(initiator_participant.user_role).to eq("entrepreneur")
  end
end
```

#### 4. Edge Case Testing
```ruby
describe "validation edge cases" do
  it "validates payment terms for different payment types" do
    # Test hourly payment without rate
    form = AgreementForm.new(valid_attributes.merge(
      payment_type: Agreement::HOURLY,
      hourly_rate: nil
    ))
    expect(form).not_to be_valid
    expect(form.errors[:hourly_rate]).to include("must be present for hourly payment")

    # Test hybrid payment missing both
    form = AgreementForm.new(valid_attributes.merge(
      payment_type: Agreement::HYBRID,
      hourly_rate: nil,
      equity_percentage: nil
    ))
    expect(form).not_to be_valid
    expect(form.errors[:hourly_rate]).to include("must be present for hybrid payment")
    expect(form.errors[:equity_percentage]).to include("must be present for hybrid payment")
  end
end
```

## Service Object Testing

### Service Testing Pattern
**Reference**: `../ruby_patterns/README.md` - Service Object Pattern

```ruby
RSpec.describe AgreementCalculationsService do
  let(:alice) { create(:user) }
  let(:bob) { create(:user) }
  let(:project) { create(:project, user: alice) }
  let(:agreement) { create(:agreement, :with_participants, :mentorship, 
                          project: project, initiator: alice, other_party: bob,
                          weekly_hours: 10, hourly_rate: 75.0) }

  describe "#initialize" do
    it "accepts an agreement" do
      service = described_class.new(agreement)
      expect(service.agreement).to eq(agreement)
    end
  end

  describe "#call" do
    it "calculates total cost for hourly agreements" do
      agreement.update!(
        start_date: Date.current,
        end_date: 4.weeks.from_now.to_date
      )
      service = described_class.new(agreement)
      
      result = service.call
      expected_cost = 4 * 10 * 75.0  # 4 weeks * 10 hours * $75
      expect(result[:total_cost]).to eq(expected_cost)
    end

    it "handles edge cases gracefully" do
      agreement.update!(hourly_rate: nil)
      service = described_class.new(agreement)
      
      expect { service.call }.not_to raise_error
      result = service.call
      expect(result[:error]).to be_present
    end
  end

  describe "private methods" do
    it "calculates weeks correctly" do
      agreement.update!(
        start_date: Date.current,
        end_date: 2.weeks.from_now.to_date
      )
      service = described_class.new(agreement)
      
      weeks = service.send(:duration_in_weeks)
      expect(weeks).to eq(2)
    end
  end
end
```

## Controller Testing Patterns

### Controller Testing with Authorization
**File**: `spec/controllers/agreements_controller_spec.rb`

```ruby
RSpec.describe AgreementsController, type: :controller do
  let(:alice) { create(:user) }
  let(:bob) { create(:user) }
  let(:project) { create(:project, user: alice) }
  let(:agreement) { create(:agreement, :with_participants, project: project, initiator: alice, other_party: bob) }

  before { sign_in alice }

  describe "GET #index" do
    it "assigns agreements" do
      get :index
      expect(assigns(:my_agreements)).to be_present
      expect(assigns(:other_party_agreements)).to be_present
    end

    it "handles filtering" do
      get :index, params: { status: "pending" }
      expect(assigns(:query).active_filters?).to be true
    end
  end

  describe "POST #accept" do
    context "when user is authorized" do
      before { sign_in bob } # Other party can accept

      it "accepts the agreement" do
        post :accept, params: { id: agreement.id }, format: :turbo_stream
        
        expect(agreement.reload.status).to eq(Agreement::ACCEPTED)
        expect(response).to have_http_status(:success)
      end
    end

    context "when user is not authorized" do
      before { sign_in create(:user) } # Random user

      it "redirects with error" do
        post :accept, params: { id: agreement.id }
        
        expect(response).to redirect_to(agreements_path)
        expect(flash[:alert]).to be_present
      end
    end
  end
end
```

## Integration Testing

### Request Testing with Multiple Scenarios
**File**: `spec/requests/agreements_integration_spec.rb`

```ruby
RSpec.describe "Agreements Integration", type: :request do
  let(:alice) { create(:user) }
  let(:bob) { create(:user) }
  let(:project) { create(:project, user: alice) }
  
  before { sign_in alice }

  describe "Agreement workflow" do
    it "completes full agreement lifecycle" do
      # Step 1: Create agreement
      post "/agreements", params: {
        agreement: {
          project_id: project.id,
          other_party_user_id: bob.id,
          agreement_type: "Mentorship",
          payment_type: "Hourly",
          hourly_rate: 75.0,
          weekly_hours: 10,
          start_date: 1.week.from_now.to_date,
          end_date: 4.weeks.from_now.to_date,
          tasks: "Help with development"
        }
      }
      
      expect(response).to redirect_to(agreements_path)
      agreement = Agreement.last
      expect(agreement.status).to eq("pending")
      
      # Step 2: Other party accepts
      sign_in bob
      patch "/agreements/#{agreement.id}/accept", headers: { "Accept" => "text/vnd.turbo-stream.html" }
      
      expect(response).to have_http_status(:success)
      expect(agreement.reload.status).to eq("accepted")
      
      # Step 3: Complete agreement
      sign_in alice
      patch "/agreements/#{agreement.id}/complete", headers: { "Accept" => "text/vnd.turbo-stream.html" }
      
      expect(response).to have_http_status(:success)
      expect(agreement.reload.status).to eq("completed")
    end

    it "handles counter offers" do
      original = create(:agreement, :with_participants, project: project, initiator: alice, other_party: bob)
      
      sign_in bob
      post "/agreements", params: {
        agreement: {
          project_id: project.id,
          other_party_user_id: alice.id,
          agreement_type: "Mentorship",
          payment_type: "Hourly",
          hourly_rate: 85.0, # Different rate
          weekly_hours: 10,
          start_date: 1.week.from_now.to_date,
          end_date: 4.weeks.from_now.to_date,
          tasks: "Help with development",
          counter_to_id: original.id
        }
      }
      
      expect(response).to redirect_to(agreements_path)
      expect(original.reload.status).to eq("countered")
      
      counter_offer = Agreement.last
      expect(counter_offer.counter_to).to eq(original)
      expect(counter_offer.hourly_rate).to eq(85.0)
    end
  end

  describe "Error handling" do
    it "handles invalid agreement creation" do
      post "/agreements", params: {
        agreement: {
          project_id: project.id,
          other_party_user_id: alice.id, # Same as initiator - should fail
          agreement_type: "Mentorship"
        }
      }
      
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("can't create agreement")
    end

    it "handles unauthorized access" do
      agreement = create(:agreement, :with_participants, project: create(:project))
      
      get "/agreements/#{agreement.id}"
      expect(response).to redirect_to(agreements_path)
      expect(flash[:alert]).to include("not authorized")
    end
  end
end
```

## Test Data Management

### Factory Usage Patterns
**Reference**: Test files show extensive factory usage

```ruby
# spec/factories/agreements.rb
FactoryBot.define do
  factory :agreement do
    project
    payment_type { Agreement::HOURLY }
    hourly_rate { 50.0 }
    start_date { 1.week.from_now.to_date }
    end_date { 4.weeks.from_now.to_date }
    tasks { "Help with project development" }
    
    trait :mentorship do
      agreement_type { Agreement::MENTORSHIP }
      weekly_hours { 10 }
      milestone_ids { [create(:milestone, project: project).id] }
    end
    
    trait :co_founder do
      agreement_type { Agreement::CO_FOUNDER }
      weekly_hours { nil }
    end
    
    trait :with_participants do
      after(:create) do |agreement, evaluator|
        initiator = evaluator.initiator || create(:user)
        other_party = evaluator.other_party || create(:user)
        
        create(:agreement_participant, agreement: agreement, user: initiator, is_initiator: true)
        create(:agreement_participant, agreement: agreement, user: other_party, is_initiator: false)
      end
    end
    
    trait :accepted do
      status { Agreement::ACCEPTED }
    end
  end
end

# Usage in tests
let(:agreement) { create(:agreement, :with_participants, :mentorship, :accepted, 
                        project: project, initiator: alice, other_party: bob) }
```

## Performance Testing

### Database Query Testing
```ruby
describe "query performance" do
  it "avoids N+1 queries when loading agreement participants" do
    agreements = create_list(:agreement, 3, :with_participants)
    
    expect {
      Agreement.includes(:agreement_participants => :user).each do |agreement|
        agreement.agreement_participants.each { |p| p.user.email }
      end
    }.not_to exceed_query_limit(4) # Initial query + includes
  end

  it "efficiently loads related data" do
    project_with_agreements = create(:project)
    create_list(:agreement, 5, :with_participants, project: project_with_agreements)
    
    expect {
      project = Project.includes(
        agreements: { agreement_participants: :user }
      ).find(project_with_agreements.id)
      
      project.agreements.each do |agreement|
        agreement.agreement_participants.each { |p| p.user.full_name }
      end
    }.not_to exceed_query_limit(3)
  end
end
```

## Test Coverage and Quality

### Coverage Expectations
- **Models**: 100% coverage for public methods, validations, and associations
- **Forms**: 100% coverage for validation logic and business rules
- **Services**: 100% coverage for public interface, edge cases handled
- **Controllers**: 90%+ coverage focusing on authorization and business logic
- **Integration**: Key user workflows covered end-to-end

### Quality Metrics
- **Test Speed**: Unit tests should run in < 1 second each
- **Integration Speed**: Integration tests should run in < 5 seconds each
- **Database Usage**: Use transactions for speed, factories for realistic data
- **Isolation**: Each test should be completely independent

## Best Practices Summary

1. **Structure Tests Clearly**: Use describe/context blocks to organize test scenarios
2. **Test Edge Cases**: Always test boundary conditions and error states  
3. **Use Appropriate Test Types**: Unit tests for business logic, integration for workflows
4. **Factory Over Fixtures**: Use FactoryBot for flexible, maintainable test data
5. **Mock External Services**: Don't hit real APIs in tests
6. **Test Database Interactions**: Verify associations and scopes work correctly
7. **Performance Awareness**: Test for N+1 queries and slow operations
8. **Real User Scenarios**: Integration tests should mirror actual user behavior
9. **Clear Assertions**: Each test should have clear, specific expectations
10. **Maintain Test Speed**: Fast tests enable frequent running during development