# Ruby Coding Patterns in FlukeBase

**Last Updated**: 2025-12-20
**Document Type**: Guide
**Audience**: Developers, AI Agents
**Ruby Version**: 3.4.7

This document outlines the Ruby coding patterns and best practices used throughout the FlukeBase codebase. **Always prefer new Ruby 3.4.7 syntax for consistency.**

> **📋 Testing Guide**: For comprehensive testing patterns that complement these implementation patterns, see [`../test_spec/ruby_testing/README.md`](../test_spec/ruby_testing/README.md)

---

## For AI Agents

### Decision Tree: Which Pattern to Use?

```
Need to write Ruby code?
│
├─ Is it a simple getter/predicate (single expression)?
│  YES → Use endless method definition ✅
│  NO → Continue
│
├─ Are you passing a block through unchanged?
│  YES → Use anonymous block forwarding (&) ✅
│  NO → Continue
│
├─ Creating a hash where variable names match keys?
│  YES → Use hash shorthand syntax ✅
│  NO → Continue
│
├─ Need an immutable value object?
│  YES → Use Data.define ✅
│  NO → Continue
│
├─ Destructuring complex nested data?
│  YES → Use pattern matching (case/in) ✅
│  NO → Continue
│
└─ Simple block with single parameter?
   YES → Use `it` keyword ✅
   NO → Use named block parameters
```

### Anti-Patterns Checklist

❌ DO NOT use verbose hash syntax when shorthand applies (`{user: user}` → `{user:}`)
❌ DO NOT use multi-line methods for single expressions
❌ DO NOT use `Struct` for immutable value objects (use `Data.define`)
❌ DO NOT use `OpenStruct` (slow, memory-heavy)
❌ DO NOT name blocks just to pass them through (`&block` → `&`)
❌ DO NOT use `_1` when `it` is available (Ruby 3.4+)
❌ DO NOT use manual hash extraction instead of pattern matching
❌ DO NOT concatenate strings (use interpolation)
✅ DO use Ruby 3.4.7 syntax consistently
✅ DO use service objects for complex business logic
✅ DO use query objects for complex filtering
✅ DO use form objects for complex form handling
✅ DO sanitize all HTML inputs
✅ DO authorize at multiple levels

---

## Ruby 3.4.7 Syntax Standards

### 1. Hash Shorthand Syntax

**Rule**: Always use shorthand when variable name matches key name.

```ruby
# ❌ OLD (anti-pattern - verbose)
def create_agreement
  initiator = current_user
  project = Project.find(params[:project_id])
  Agreement.create(initiator: initiator, project: project)
end

# ✅ NEW (preferred - Ruby 3.4.7)
def create_agreement
  initiator = current_user
  project = Project.find(params[:project_id])
  Agreement.create(initiator:, project:)
end
```

**FlukeBase Examples**:

| Context | Old | New |
|---------|-----|-----|
| Agreement creation | `Agreement.create(initiator: initiator, project: project)` | `Agreement.create(initiator:, project:)` |
| Milestone creation | `Milestone.new(agreement: agreement, title: title)` | `Milestone.new(agreement:, title:)` |
| Message sending | `Message.create(conversation: conversation, sender: sender)` | `Message.create(conversation:, sender:)` |
| TimeLog | `TimeLog.create(user: user, milestone: milestone)` | `TimeLog.create(user:, milestone:)` |

---

### 2. Endless Method Definitions

**Rule**: Use for single-expression methods that fit on one line.

```ruby
# ❌ OLD (anti-pattern for simple getters)
def pending?
  status == "pending"
end

def active?
  status == "active"
end

def total_hours
  time_logs.sum(:duration) / 3600.0
end

# ✅ NEW (preferred - Ruby 3.4.7)
def pending? = status == "pending"
def active? = status == "active"
def total_hours = time_logs.sum(:duration) / 3600.0
```

**FlukeBase Model Examples**:

| Model | Method | Implementation |
|-------|--------|----------------|
| Agreement | `def pending? = status == "pending"` |
| Agreement | `def active? = status == "active"` |
| Agreement | `def completed? = status == "completed"` |
| Project | `def public? = visibility == "public"` |
| Project | `def private? = visibility == "private"` |
| Milestone | `def overdue? = due_date&.past?` |
| Milestone | `def completed? = completed_at.present?` |
| User | `def has_projects? = projects.exists?` |
| TimeLog | `def running? = ended_at.nil?` |

---

### 3. `it` Block Parameter (Ruby 3.4+)

**Rule**: Use `it` for single-parameter blocks. Preferred over `_1`.

```ruby
# ❌ OLD (anti-pattern in Ruby 3.4.7)
projects.map { |project| project.title }
agreements.select { |a| a.active? }
time_logs.sum { |t| t.duration }

# ⚠️ TRANSITIONAL (acceptable but not preferred)
projects.map { _1.title }

# ✅ NEW (preferred - Ruby 3.4.7)
projects.map { it.title }
agreements.select { it.active? }
time_logs.sum { it.duration }
```

**FlukeBase Examples**:

| Context | Old | New |
|---------|-----|-----|
| Project titles | `projects.map { \|p\| p.title }` | `projects.map { it.title }` |
| Active agreements | `agreements.select { \|a\| a.active? }` | `agreements.select { it.active? }` |
| Total hours | `time_logs.sum { \|t\| t.duration }` | `time_logs.sum { it.duration }` |
| Pending milestones | `milestones.reject { \|m\| m.completed? }` | `milestones.reject { it.completed? }` |
| User emails | `users.map { \|u\| u.email }` | `users.map { it.email }` |

---

### 4. Anonymous Block Forwarding

**Rule**: Use `&` without naming when block is just passed through.

```ruby
# ❌ OLD (anti-pattern - unnecessary naming)
def with_transaction(&block)
  ActiveRecord::Base.transaction(&block)
end

# ✅ NEW (preferred - Ruby 3.4.7)
def with_transaction(&)
  ActiveRecord::Base.transaction(&)
end
```

---

### 5. Argument Forwarding

**Rule**: Use `...` for complete argument forwarding.

```ruby
# ❌ OLD (anti-pattern - verbose)
def log_and_create(*args, **kwargs, &block)
  Rails.logger.info("Creating agreement")
  Agreement.create(*args, **kwargs, &block)
end

# ✅ NEW (preferred - Ruby 3.4.7)
def log_and_create(...)
  Rails.logger.info("Creating agreement")
  Agreement.create(...)
end
```

---

### 6. Data.define for Value Objects

**Rule**: Use `Data.define` instead of `Struct` for immutable value objects.

```ruby
# ❌ OLD (anti-pattern - mutable by default)
PaymentTerm = Struct.new(:amount, :currency, :due_date, keyword_init: true)

# ✅ NEW (preferred - Ruby 3.4.7)
PaymentTerm = Data.define(:amount, :currency, :due_date) do
  def formatted = "#{currency}#{amount}"
  def overdue? = due_date&.past?
end

MilestoneProgress = Data.define(:completed, :total, :percentage) do
  def complete? = completed == total
  def on_track? = percentage >= 50
end

AgreementResult = Data.define(:success, :agreement, :errors) do
  def success? = success
  def failure? = !success
end
```

**FlukeBase Value Objects**:

| Value Object | Implementation |
|--------------|----------------|
| PaymentTerm | `Data.define(:amount, :currency, :due_date)` |
| MilestoneProgress | `Data.define(:completed, :total, :percentage)` |
| TimeLogSummary | `Data.define(:total_hours, :billable_hours, :period)` |
| AgreementStats | `Data.define(:active_count, :completed_count, :pending_count)` |
| GitHubCommitInfo | `Data.define(:sha, :message, :author, :timestamp)` |

---

### 7. Pattern Matching Destructuring

**Rule**: Use pattern matching for complex hash/array destructuring.

```ruby
# ❌ OLD (anti-pattern - manual extraction)
def process_github_webhook(payload)
  if payload[:action] == "push"
    repo = payload[:repository][:full_name]
    commits = payload[:commits]
    # process...
  end
end

# ✅ NEW (preferred - Ruby 3.4.7)
def process_github_webhook(payload)
  case payload
  in { action: "push", repository: { full_name: }, commits: }
    # full_name and commits are now local variables
    sync_commits(full_name, commits)
  in { action: "pull_request", pull_request: { number:, state: } }
    update_pr_status(number, state)
  in { action: "issues", issue: { number:, title: } }
    sync_issue(number, title)
  end
end
```

**FlukeBase Examples**:

| Context | Pattern |
|---------|---------|
| GitHub push | `in { action: "push", repository: { full_name: }, commits: }` |
| Payment webhook | `in { event: "payment.completed", data: { agreement_id:, amount: } }` |
| Stripe event | `in { type: "invoice.paid", data: { object: { id:, amount_paid: } } }` |

---

### 8. String Interpolation

**Rule**: Always use interpolation over concatenation.

```ruby
# ❌ OLD (anti-pattern)
message = "Agreement " + agreement.id.to_s + " created by " + user.name
path = base_path + "/" + project.slug

# ✅ NEW (preferred)
message = "Agreement #{agreement.id} created by #{user.name}"
path = "#{base_path}/#{project.slug}"
```

---

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