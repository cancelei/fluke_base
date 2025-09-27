# FlukeBase Test Cross-Reference Guide

This document provides quick reference mappings between our test specifications and implemented tests, enabling developers to quickly find the correct patterns and examples for their testing needs.

## 📚 Test Specification Structure

### Primary Documentation
- **Main Spec**: `technical_spec/test_spec/README.md` - Overview and structure
- **Ruby Testing**: `technical_spec/test_spec/ruby_testing/README.md` - Model, service, form patterns
- **Turbo Testing**: `technical_spec/test_spec/turbo_testing/README.md` - Hotwire/Turbo patterns
- **Stimulus Testing**: `technical_spec/test_spec/stimulus_testing/README.md` - JavaScript controller patterns

## 🔍 Quick Reference by Test Type

### Model Testing Patterns
**Spec Location**: `technical_spec/test_spec/ruby_testing/README.md:42-349`

| Pattern | Spec Lines | Implementation Examples |
|---------|------------|-------------------------|
| **Association Testing** | Lines 49-58 | `spec/models/user_spec.rb:9-22`<br>`spec/models/project_spec.rb:10-21`<br>`spec/models/agreement_spec.rb:12-23` |
| **Validation Testing** | Lines 60-102 | `spec/models/user_spec.rb:24-42`<br>`spec/models/project_spec.rb:23-47`<br>`spec/models/milestone_spec.rb:18-42` |
| **Business Logic Testing** | Lines 129-148 | `spec/models/user_spec.rb:44-71`<br>`spec/models/project_spec.rb:49-100`<br>`spec/models/conversation_spec.rb:34-79` |
| **Scope Testing** | Lines 104-126 | `spec/models/project_spec.rb:102-143`<br>`spec/models/milestone_spec.rb:95-126`<br>`spec/models/meeting_spec.rb:108-138` |
| **Complex Method Testing** | Lines 150-166 | `spec/models/agreement_spec.rb:150-200`<br>`spec/models/time_log_spec.rb:89-120` |
| **Factory Integration** | Lines 507-549 | `spec/models/user_spec.rb:73-86`<br>`spec/models/project_spec.rb:145-161` |

### Service Object Testing Patterns
**Spec Location**: `technical_spec/test_spec/ruby_testing/README.md:350-450`

| Pattern | Spec Lines | Implementation Examples |
|---------|------------|-------------------------|
| **Service Initialization** | Lines 360-375 | `spec/services/agreement_calculations_service_spec.rb:8-25` |
| **Business Logic Methods** | Lines 380-420 | `spec/services/agreement_calculations_service_spec.rb:27-120` |
| **Error Handling** | Lines 425-445 | `spec/services/agreement_calculations_service_spec.rb:267-301` |
| **Integration Testing** | Lines 315-330 | `spec/services/agreement_status_service_spec.rb:200-230` |

### Form Object Testing Patterns
**Spec Location**: `technical_spec/test_spec/ruby_testing/README.md:451-506`

| Pattern | Spec Lines | Implementation Examples |
|---------|------------|-------------------------|
| **Validation Testing** | Lines 460-480 | `spec/forms/agreement_form_spec.rb:15-45` |
| **Data Handling** | Lines 485-500 | `spec/forms/agreement_form_spec.rb:50-85` |
| **Persistence Logic** | Lines 505-520 | `spec/forms/project_form_spec.rb:40-70` |

### Turbo Testing Patterns
**Spec Location**: `technical_spec/test_spec/turbo_testing/README.md:1-300`

| Pattern | Spec Lines | Implementation Examples |
|---------|------------|-------------------------|
| **Turbo Frame Testing** | Lines 45-90 | `spec/system/agreement_workflow_spec.rb:45-65`<br>`spec/system/complete_user_journey_spec.rb:78-95` |
| **Turbo Stream Testing** | Lines 95-140 | `spec/system/agreement_workflow_spec.rb:85-105`<br>`spec/system/complete_user_journey_spec.rb:110-130` |
| **Lazy Loading Testing** | Lines 145-180 | `spec/system/turbo_frames_spec.rb:120-150` |
| **Form Integration** | Lines 185-220 | `spec/system/agreement_workflow_spec.rb:25-45` |
| **Real-time Updates** | Lines 225-260 | `spec/system/complete_user_journey_spec.rb:200-250` |
| **Error Handling** | Lines 265-290 | `spec/system/agreement_workflow_spec.rb:180-210` |

### Stimulus Testing Patterns
**Spec Location**: `technical_spec/test_spec/stimulus_testing/README.md:1-250`

| Pattern | Spec Lines | Implementation Examples |
|---------|------------|-------------------------|
| **Controller Setup** | Lines 25-45 | `spec/system/stimulus_controllers_spec.rb:15-35` |
| **Unit Testing Controllers** | Lines 50-120 | `spec/system/stimulus_controllers_spec.rb:40-120` |
| **Integration with Rails** | Lines 125-160 | `spec/system/complete_user_journey_spec.rb:150-180` |
| **Event Handling** | Lines 165-200 | `spec/system/messaging_collaboration_spec.rb:45-85` |
| **Media Controller Testing** | Lines 205-240 | `spec/system/messaging_collaboration_spec.rb:35-120` |

## 🎯 Quick Search by Feature

### Authentication & Authorization
- **User Model**: `spec/models/user_spec.rb` → Spec: `ruby_testing/README.md:42-349`
- **Request Authentication**: `spec/requests/*_spec.rb` → Helper: `spec/support/authentication_helpers.rb`
- **System Authentication**: `spec/system/*_spec.rb` → Pattern: Sign-in helpers

### Time Tracking
- **TimeLog Model**: `spec/models/time_log_spec.rb` → Spec: `ruby_testing/README.md:42-349`
- **Timer Controller**: `spec/system/time_tracking_workflow_spec.rb:15-80` → Spec: `stimulus_testing/README.md:50-120`
- **Time Calculations**: `spec/services/agreement_calculations_service_spec.rb` → Spec: `ruby_testing/README.md:350-450`

### Project Management
- **Project Model**: `spec/models/project_spec.rb` → Spec: `ruby_testing/README.md:42-349`
- **Milestone Model**: `spec/models/milestone_spec.rb` → Spec: `ruby_testing/README.md:42-349`
- **Project Workflows**: `spec/system/complete_user_journey_spec.rb:15-50` → Spec: `turbo_testing/README.md:1-300`

### Agreement System
- **Agreement Model**: `spec/models/agreement_spec.rb` → Spec: `ruby_testing/README.md:42-349`
- **Agreement Forms**: `spec/forms/agreement_form_spec.rb` → Spec: `ruby_testing/README.md:451-506`
- **Agreement Workflows**: `spec/system/agreement_workflow_spec.rb` → Spec: `turbo_testing/README.md:1-300`
- **Status Management**: `spec/services/agreement_status_service_spec.rb` → Spec: `ruby_testing/README.md:350-450`

### Messaging & Collaboration
- **Message Model**: `spec/models/message_spec.rb` → Spec: `ruby_testing/README.md:42-349`
- **Conversation Model**: `spec/models/conversation_spec.rb` → Spec: `ruby_testing/README.md:42-349`
- **Voice Recording**: `spec/system/messaging_collaboration_spec.rb:35-120` → Spec: `stimulus_testing/README.md:205-240`
- **Meeting Management**: `spec/models/meeting_spec.rb` → Spec: `ruby_testing/README.md:42-349`

### GitHub Integration
- **GitHub Models**: `spec/models/github_*_spec.rb` → Spec: `ruby_testing/README.md:42-349`
- **GitHub Jobs**: `spec/jobs/github_*_spec.rb` → Spec: `ruby_testing/README.md:550-600`

## 🛠️ Development Workflow Quick Reference

### Adding New Model Tests
1. **Reference Pattern**: `technical_spec/test_spec/ruby_testing/README.md:42-349`
2. **Copy Structure**: Use `spec/models/user_spec.rb` as template
3. **Key Sections**: Associations (49-58) → Validations (60-102) → Business Logic (129-148)
4. **Factory Integration**: Lines 507-549 in spec

### Adding New System Tests
1. **Reference Pattern**: `technical_spec/test_spec/turbo_testing/README.md:1-300`
2. **Copy Structure**: Use `spec/system/complete_user_journey_spec.rb` as template
3. **Turbo Patterns**: Frames (45-90) → Streams (95-140) → Forms (185-220)
4. **Stimulus Integration**: `stimulus_testing/README.md:125-160`

### Adding New Service Tests
1. **Reference Pattern**: `technical_spec/test_spec/ruby_testing/README.md:350-450`
2. **Copy Structure**: Use `spec/services/agreement_calculations_service_spec.rb`
3. **Key Sections**: Initialization (360-375) → Logic (380-420) → Errors (425-445)

### Performance Testing
1. **Reference Pattern**: `technical_spec/test_spec/ruby_testing/README.md:554-600`
2. **Implementation**: `spec/performance/agreement_performance_spec.rb`
3. **N+1 Prevention**: `spec/support/performance_helpers.rb`

## 📋 Test Helper Cross-Reference

### Authentication Helpers
- **File**: `spec/support/authentication_helpers.rb`
- **Usage**: `sign_in_alice`, `sign_in_user(user)`, `with_users(alice: true)`
- **Reference**: Request specs and system tests

### Turbo Helpers
- **File**: `spec/support/turbo_helpers.rb`
- **Usage**: `wait_for_turbo_stream`, `have_turbo_frame`, `within_turbo_frame`
- **Reference**: `turbo_testing/README.md:30-44`

### Stimulus Helpers
- **File**: `spec/support/stimulus_helpers.rb`
- **Usage**: `have_stimulus_controller`, `stimulus_controller_state`
- **Reference**: `stimulus_testing/README.md:15-30`

### Performance Helpers
- **File**: `spec/support/performance_helpers.rb`
- **Usage**: `expect_query_count`, `benchmark_operation`
- **Reference**: `ruby_testing/README.md:554-600`

## 🎨 Coverage Configuration Cross-Reference

### Coverage Settings
- **File**: `spec/support/coverage.rb`
- **Thresholds**: 75% overall, 50% per-file minimum
- **Tiered Requirements**: Models/Controllers/Services: 90%, Helpers/Presenters: 80%
- **Reference**: `TEST_IMPLEMENTATION_SUMMARY.md:Enhanced Coverage Configuration`

### Running Tests with Coverage
```bash
# Full coverage analysis
COVERAGE=true bundle exec rake test

# Quick model tests
bundle exec rspec spec/models/ --format progress

# System tests with JS
bundle exec rspec spec/system/ --tag js
```

## 🚀 Common Patterns Quick Access

### Model Validation Pattern
```ruby
# Reference: ruby_testing/README.md:60-102
describe "validations" do
  subject { create(:model_name) }
  
  it { should validate_presence_of(:field) }
  it { should validate_uniqueness_of(:field) }
  # ... more validations
end
```

### Turbo Frame Pattern
```ruby
# Reference: turbo_testing/README.md:45-90
expect(page).to have_turbo_frame("frame_id")
within_turbo_frame("frame_id") do
  expect(page).to have_content("Expected content")
end
```

### Stimulus Controller Pattern
```ruby
# Reference: stimulus_testing/README.md:50-120
expect(page).to have_stimulus_controller("controller-name")
find("[data-controller-target='button']").click
expect(page).to have_css("[data-controller-target='result']")
```

### Service Testing Pattern
```ruby
# Reference: ruby_testing/README.md:350-450
describe "ServiceName" do
  let(:service) { ServiceName.new(params) }
  
  describe "#method_name" do
    it "performs expected operation" do
      result = service.method_name
      expect(result).to eq(expected_value)
    end
  end
end
```

---

## 📖 How to Use This Reference

1. **Find Your Test Type**: Look up the pattern you need in the Quick Reference tables
2. **Check Spec Lines**: Reference the specific lines in our documentation for detailed patterns
3. **Copy Implementation**: Use the provided implementation examples as templates
4. **Cross-Reference**: Use the feature-based search to find related tests
5. **Follow Patterns**: Maintain consistency with established patterns and helpers

This cross-reference ensures that all developers can quickly find the right testing patterns and maintain consistency across the FlukeBase test suite.


