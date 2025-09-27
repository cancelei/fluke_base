# Ruby Coding Patterns in FlukeBase

This document outlines the Ruby coding patterns and best practices used throughout the FlukeBase codebase.

> **📋 Testing Guide**: For comprehensive testing patterns that complement these implementation patterns, see [`../test_spec/ruby_testing/README.md`](../test_spec/ruby_testing/README.md)

## Table of Contents

1. [Model Architecture](#model-architecture)
2. [Controller Patterns](#controller-patterns)
3. [Service Object Pattern](#service-object-pattern)
4. [Query Object Pattern](#query-object-pattern)
5. [Form Object Pattern](#form-object-pattern)
6. [Association Patterns](#association-patterns)
7. [Validation Patterns](#validation-patterns)
8. [Security Patterns](#security-patterns)

## Model Architecture

### Base Model Structure
All models inherit from `ApplicationRecord` and follow standard Rails conventions:

**File**: `app/models/application_record.rb`
```ruby
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end
```

### Complex Model Example: User
**File**: `app/models/user.rb:1-86`

Key patterns observed:
- **Explicit Association Ordering**: Associations defined before concerns
- **Concern Usage**: Modular functionality via `include UserAgreements`, `include UserMessaging`
- **Devise Integration**: Standard authentication setup
- **Pay Integration**: Billing capabilities with `include Pay::Billable`
- **Custom Validations**: GitHub-specific validations with regex patterns
- **Service Object Delegation**: Avatar handling delegated to `AvatarService`
- **Memoization**: Instance variable caching (`@avatar_service`)

```ruby
class User < ApplicationRecord
  # Associations first - explicit ordering
  belongs_to :selected_project, class_name: "Project", optional: true
  has_many :agreement_participants, dependent: :delete_all
  
  # Complex associations with lambdas for filtering
  has_many :initiated_agreements, 
    -> { where(agreement_participants: { is_initiator: true }) },
    through: :agreement_participants, source: :agreement
    
  # Concerns after base associations
  include UserAgreements
  include UserMessaging
  
  # External integrations
  devise :database_authenticatable, :registerable, ...
  include Pay::Billable
  
  # Custom methods with service delegation
  def avatar_url
    @avatar_service ||= AvatarService.new(self)
    @avatar_service.url
  end
end
```

### Complex Model Example: Project
**File**: `app/models/project.rb:1-281`

Key patterns:
- **Constants for State Management**: `IDEA = "idea"`, `SEEKING_MENTOR = "mentor"`
- **Lifecycle Hooks**: `before_save :set_defaults`
- **Complex Query Methods**: GitHub integration with proper includes
- **Service Object Pattern**: Delegation to `ProjectGithubService`, `ProjectVisibilityService`
- **Scopes for Business Logic**: `scope :seeking_mentor`, `scope :ideas`
- **Method Chaining**: Complex queries with proper error handling

## Controller Patterns

### Base Controller Structure
**File**: `app/controllers/application_controller.rb:1-160`

Key patterns:
- **CanCan Integration**: Authorization with `include CanCan::ControllerAdditions`
- **Browser Compatibility**: `allow_browser versions: { chrome: 100, safari: 15, ... }`
- **DRY Helper Methods**: `find_resource_or_redirect` for common patterns
- **Turbo Stream Helpers**: Custom methods for different message types

### Complex Controller Example: AgreementsController
**File**: `app/controllers/agreements_controller.rb:1-786`

Advanced patterns observed:

#### 1. Turbo Frame Handling
```ruby
def index
  respond_to do |format|
    format.html do
      if turbo_frame_request?
        case request.headers["Turbo-Frame"]
        when "agreement_results"
          render partial: "agreement_results", layout: false
        when "agreements_my"
          render partial: "my_agreements_section", layout: false
        end
      end
    end
  end
end
```

#### 2. Query Object Integration
```ruby
def index
  @query = AgreementsQuery.new(current_user, filter_params)
  @my_agreements = @query.my_agreements
  @other_party_agreements = @query.other_party_agreements
end
```

#### 3. Form Object Pattern
```ruby
def create
  @agreement_form = AgreementForm.new(form_params)
  if @agreement_form.save
    # Handle success
  else
    # Handle validation errors
  end
end
```

#### 4. Lazy Loading with Turbo Frames
```ruby
def meetings_section
  begin
    @meetings = @agreement.meetings.includes(:user).order(start_time: :asc)
    respond_to do |format|
      format.turbo_stream { 
        render turbo_stream: turbo_stream.replace(
          "#{dom_id(@agreement)}_meetings", 
          partial: "meetings_section"
        )
      }
    end
  rescue => e
    # Error handling with fallback UI
  end
end
```

## Service Object Pattern

Services are used for complex business logic:

### Examples from Codebase:
- `AvatarService` - User avatar management
- `ProjectGithubService` - GitHub integration
- `ProjectVisibilityService` - Field visibility logic
- `EnhancedMilestoneService` - AI-powered milestone enhancement
- `NotificationService` - User notifications

**Pattern Structure**:
```ruby
class ExampleService
  def initialize(model, options = {})
    @model = model
    @options = options
  end
  
  def call
    # Main business logic
  end
  
  private
  
  def helper_method
    # Private implementation
  end
end
```

## Association Patterns

### Complex Associations with Lambda Scopes
**File**: `app/models/user.rb:9-12`
```ruby
has_many :initiated_agreements, 
  -> { where(agreement_participants: { is_initiator: true }) },
  through: :agreement_participants, source: :agreement
```

### Polymorphic Associations with Proper Indexing
**File**: `app/models/project.rb:44-46`
```ruby
has_many :github_logs, dependent: :destroy
has_many :github_branches, dependent: :destroy
```

### Through Associations for Complex Relationships
**File**: `app/models/project.rb:9-10`
```ruby
has_many :mentorships, 
  -> { where(agreement_type: "Mentorship") }, 
  class_name: "Agreement", foreign_key: "project_id"
has_many :mentors, through: :mentorships, source: :other_party
```

## Validation Patterns

### Custom Regex Validations
**File**: `app/models/user.rb:28`
```ruby
validates :github_username, 
  format: { 
    with: /\A[a-z\d](?:[a-z\d]|-(?=[a-z\d])){0,38}\z/i, 
    message: "is not a valid GitHub username", 
    allow_blank: true 
  }
```

### Complex URL Validations
**File**: `app/models/project.rb:18-22`
```ruby
validates :repository_url, format: {
  with: %r{\A(\z|https?://github\.com/[^/]+/[^/]+|[^/\s]+/[^/\s]+)\z},
  message: "must be a valid GitHub repository URL or username/repository format"
}, allow_blank: true
```

## Security Patterns

### Input Sanitization
**File**: `app/controllers/agreements_controller.rb:726-729`
```ruby
def agreement_params
  permitted_params = params.require(:agreement).permit(...)
  
  # Sanitize HTML content for security
  permitted_params[:tasks] = ActionController::Base.helpers.sanitize(permitted_params[:tasks])
  permitted_params[:terms] = ActionController::Base.helpers.sanitize(permitted_params[:terms])
  
  permitted_params
end
```

### Authorization Patterns
**File**: `app/controllers/agreements_controller.rb:658-676`
```ruby
def authorize_agreement
  authorized = (
    current_user.id == @agreement.initiator&.id ||
    current_user.id == @agreement.other_party&.id
  )
  
  # Additional authorization for counter offers
  if !authorized && @agreement.counter_to_id.present?
    original = @agreement.counter_to
    authorized = (
      original.present? &&
      (current_user.id == original.initiator&.id || 
       current_user.id == original.other_party&.id)
    )
  end
  
  unless authorized
    redirect_to agreements_path, alert: "You are not authorized to view this agreement."
  end
end
```

### CSRF Protection
**File**: `app/controllers/application_controller.rb:5`
```ruby
protect_from_forgery with: :exception
```

## Best Practices Summary

1. **Explicit Association Ordering**: Define basic associations before including concerns
2. **Service Object Delegation**: Move complex logic to service objects
3. **Query Object Pattern**: Use for complex filtering and searching
4. **Form Object Pattern**: Handle complex form logic outside models
5. **Proper Error Handling**: Always rescue and provide fallbacks
6. **Input Sanitization**: Sanitize all HTML inputs
7. **Authorization Everywhere**: Check permissions at multiple levels
8. **Memoization**: Cache expensive operations with instance variables
9. **Constants for State**: Use constants instead of magic strings
10. **Turbo-First Architecture**: Design for real-time updates from the start