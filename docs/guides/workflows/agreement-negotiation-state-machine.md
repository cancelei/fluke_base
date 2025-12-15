# Agreement Negotiation State Machine

**Last Updated**: 2025-12-13
**Document Type**: Guide
**Audience**: Developers, AI Agents

Turn-based negotiation system for mentorship and co-founder agreements with counter-offer support.

---

## For AI Agents

### Decision Tree: Can user take action on agreement?

```
What action is user attempting?
│
├─ ACCEPT
│  ├─ Is agreement.status == PENDING?
│  │  ├─ YES: Is whose_turn? == current_user?
│  │  │  ├─ YES → Call agreement.accept! ✅ PROCEED
│  │  │  └─ NO → ❌ REJECT "Not your turn"
│  │  └─ NO → ❌ REJECT "Cannot accept non-pending agreement"
│  │
├─ COUNTER OFFER
│  ├─ Is agreement.status == PENDING?
│  │  ├─ YES: user_can_make_counter_offer?(current_user)?
│  │  │  ├─ YES → Create counter agreement ✅ PROCEED
│  │  │  └─ NO → ❌ REJECT "Not your turn"
│  │  └─ NO → ❌ REJECT "Cannot counter non-pending agreement"
│  │
├─ REJECT
│  ├─ Is agreement.status == PENDING?
│  │  ├─ YES: user_can_reject?(current_user)?
│  │  │  ├─ YES → Call agreement.reject! ✅ PROCEED
│  │  │  └─ NO → ❌ REJECT "Not your turn"
│  │  └─ NO → ❌ REJECT "Cannot reject non-pending agreement"
│  │
├─ CANCEL
│  ├─ Is agreement.status == PENDING?
│  │  ├─ YES: Is current_user == initiator?
│  │  │  ├─ YES → Call agreement.cancel! ✅ PROCEED
│  │  │  └─ NO → ❌ REJECT "Only initiator can cancel"
│  │  └─ NO → ❌ REJECT "Cannot cancel non-pending agreement"
│  │
└─ COMPLETE
   ├─ Is agreement.status == ACCEPTED?
   │  ├─ YES: Is current_user a participant?
   │  │  ├─ YES → Call agreement.complete! ✅ PROCEED
   │  │  └─ NO → ❌ REJECT "Not a participant"
   │  └─ NO → ❌ REJECT "Cannot complete non-active agreement"
```

### Anti-Patterns

❌ DO NOT update `agreement.status` directly (use service methods)
❌ DO NOT allow actions outside of user's turn
❌ DO NOT forget to pass turn after counter offer
❌ DO NOT manually set `accept_or_counter_turn_id` (use pass_turn methods)
❌ DO NOT create counter without linking via `counter_agreement_id`
✅ DO use `AgreementStatusService` for all status changes
✅ DO check `user_can_make_counter_offer?(user)` before showing UI
✅ DO track counter offers via `agreement_participants.counter_agreement_id`
✅ DO use `whose_turn?` to determine current turn holder

---

## State Diagram

```
           CREATE (initiator)
              │
              ▼
          PENDING ◄──────────────────┐
              │                      │
              ├─accept!──────►ACCEPTED────complete!────►COMPLETED
              │
              ├─reject!──────►REJECTED
              │
              ├─cancel!──────►CANCELLED
              │  (initiator only)
              │
              └─counter_offer!───►COUNTERED
                                       │
                                       └──creates new──►PENDING
                                          (with counter_agreement_id)
```

**File**: `/app/models/agreement.rb` (lines 3-12)

### Status Constants

```ruby
PENDING = "Pending"        # Awaiting acceptance or counter
ACCEPTED = "Accepted"      # Both parties agreed, work active
COMPLETED = "Completed"    # Work finished successfully
REJECTED = "Rejected"      # Explicitly declined by recipient
CANCELLED = "Cancelled"    # Cancelled by initiator before acceptance
COUNTERED = "Countered"    # Counter offer made (original agreement)
```

### Agreement Types

```ruby
MENTORSHIP = "Mentorship"   # Time-bounded mentorship engagement
CO_FOUNDER = "Co-Founder"   # Long-term co-founder partnership
```

### Payment Types

```ruby
HOURLY = "Hourly"      # Hourly rate compensation
EQUITY = "Equity"      # Equity-only compensation
HYBRID = "Hybrid"      # Hourly rate + equity
```

---

## Turn-Based System

### Turn Tracking

**File**: `/app/models/agreement_participant.rb`

Each participant record has:
```ruby
accept_or_counter_turn_id  # Integer: ID of user whose turn it is to act
```

**Critical**: All participants in the same agreement share the **same** `accept_or_counter_turn_id` value.

### Turn Flow

```
1. Initiator creates agreement
      ↓
   Turn = Other Party (recipient)
      ↓
2. Recipient chooses:
   - ACCEPT → Agreement status = ACCEPTED ✅
   - COUNTER → Creates new agreement, Turn = Initiator
   - REJECT → Agreement status = REJECTED ❌
      ↓
3. If COUNTER:
   Turn = Initiator (original creator)
      ↓
4. Initiator chooses:
   - ACCEPT → New agreement status = ACCEPTED ✅
   - COUNTER → Creates another new agreement, Turn = Other Party
   - REJECT → New agreement status = REJECTED ❌
      ↓
   (continues until ACCEPT/REJECT)
```

### Turn Methods

**File**: `/app/models/agreement.rb` (lines 143-171)

#### Check Whose Turn

```ruby
def whose_turn?
  turn_user_id = agreement_participants.first&.accept_or_counter_turn_id
  User.find_by(id: turn_user_id) if turn_user_id
end
```

**Usage**:
```ruby
agreement.whose_turn?  # => User object or nil
```

#### Check User Permissions

```ruby
def user_can_accept_or_counter?(user)
  participant = participant_for_user(user)
  participant&.accept_or_counter_turn_id == user.id
end

def user_can_make_counter_offer?(user)
  participant = participant_for_user(user)
  participant&.can_make_counter_offer?
end

def user_can_accept?(user)
  participant = participant_for_user(user)
  participant&.can_accept_agreement?
end

def user_can_reject?(user)
  participant = participant_for_user(user)
  participant&.can_reject_agreement?
end
```

#### Pass Turn

```ruby
def pass_turn_to_user(user)
  agreement_participants.update_all(accept_or_counter_turn_id: user.id)
end

def pass_turn_to_other_party(current_user)
  other_participant = agreement_participants.where.not(user_id: current_user.id).first
  pass_turn_to_user(other_participant.user) if other_participant
end
```

**Critical**: `pass_turn_to_other_party` is called after creating counter offer

---

## Counter Offer Chain

### How Counter Offers Work

**Problem**: Need to track negotiation history without losing original terms
**Solution**: Create new Agreement records linked to original via `counter_agreement_id`

**File**: `/app/services/agreement_status_service.rb` (line 26)

```ruby
def counter_offer!(counter_agreement)
  return false unless @agreement.pending?

  # Mark original agreement as COUNTERED
  @agreement.update(status: Agreement::COUNTERED)

  # Link new agreement to original via participants
  counter_agreement.agreement_participants.each do |participant|
    participant.update!(counter_agreement_id: @agreement.id)
  end

  counter_agreement.status = Agreement::PENDING
  counter_agreement.save
end
```

### Counter Offer Relationships

```
Original Agreement (id=1)
    status: COUNTERED
    counter_to_id: nil (no counter_agreement_id on participants)
        │
        └──► Counter Offer 1 (id=2)
                 status: COUNTERED
                 participants.counter_agreement_id: 1
                     │
                     └──► Counter Offer 2 (id=3)
                              status: PENDING
                              participants.counter_agreement_id: 1
                                  │
                                  └──► Counter Offer 3 (id=4)
                                           status: ACCEPTED
                                           participants.counter_agreement_id: 1
```

**Note**: All counter offers link back to the **original** agreement (id=1), not to the immediate parent.

### Tracking Methods

**File**: `/app/models/agreement.rb` (lines 267-300)

#### Is This a Counter Offer?

```ruby
def is_counter_offer?
  agreement_participants.any?(&:counter_agreement_id)
end
```

#### Get Original Agreement

```ruby
def counter_to_id
  # Get the ID of the original agreement this is a counter offer to
  agreement_participants.first&.counter_agreement_id
end

def counter_to
  # Get the original agreement this is a counter offer to
  counter_agreement_id = counter_to_id
  Agreement.find_by(id: counter_agreement_id) if counter_agreement_id
end
```

#### Get All Counter Offers

```ruby
def counter_offers
  # Get all agreements that are counter offers to this one
  Agreement.joins(:agreement_participants)
          .where(agreement_participants: { counter_agreement_id: id })
          .distinct
end

def has_counter_offers?
  counter_offers.exists?
end

def most_recent_counter_offer
  counter_offers.order(created_at: :desc).first
end

def latest_counter_offer
  most_recent_counter_offer
end
```

---

## State Transitions

### Accept Transition

**File**: `/app/services/agreement_status_service.rb` (line 6)

```ruby
def accept!
  return false unless @agreement.pending?
  @agreement.update(status: Agreement::ACCEPTED)
end
```

**Model Delegation** (line 221):
```ruby
def accept!
  status_service.accept!
end
```

**Effects**:
- Agreement status → ACCEPTED
- Time tracking becomes available
- Both parties get project access
- Milestones become trackable

**Validation**: Only works if `status == PENDING`

---

### Reject Transition

**File**: `/app/services/agreement_status_service.rb` (line 11)

```ruby
def reject!
  return false unless @agreement.pending?
  @agreement.update(status: Agreement::REJECTED)
end
```

**Effects**:
- Agreement status → REJECTED
- Agreement is closed (no further actions)
- Negotiation ends
- No time tracking or project access

**Validation**: Only works if `status == PENDING`

---

### Cancel Transition

**File**: `/app/services/agreement_status_service.rb` (line 21)

```ruby
def cancel!
  return false unless @agreement.pending?
  @agreement.update(status: Agreement::CANCELLED)
end
```

**Effects**:
- Agreement status → CANCELLED
- Initiator-only action (before acceptance)
- Ends negotiation without recipient action

**Validation**:
- Only works if `status == PENDING`
- Only initiator can cancel (check in controller)

---

### Complete Transition

**File**: `/app/services/agreement_status_service.rb` (line 16)

```ruby
def complete!
  return false unless @agreement.active?
  @agreement.update(status: Agreement::COMPLETED)
end
```

**Effects**:
- Agreement status → COMPLETED
- Work is finished
- Final state (no further transitions)

**Validation**: Only works if `status == ACCEPTED` (active?)

---

### Counter Offer Transition

**File**: `/app/services/agreement_status_service.rb` (line 26)

```ruby
def counter_offer!(counter_agreement)
  return false unless @agreement.pending?

  # Mark original as COUNTERED
  @agreement.update(status: Agreement::COUNTERED)

  # Link new agreement to original via participants
  counter_agreement.agreement_participants.each do |participant|
    participant.update!(counter_agreement_id: @agreement.id)
  end

  counter_agreement.status = Agreement::PENDING
  counter_agreement.save
end
```

**Controller Flow**:

**File**: `/app/controllers/agreements_controller.rb#counter_offer`

```ruby
def counter_offer
  original = Agreement.find(params[:id])

  # User must have turn
  unless original.user_can_make_counter_offer?(current_user)
    redirect_to root_path, alert: "Not your turn to make a counter offer"
    return
  end

  # Create new agreement with modified terms
  counter = Agreement.new(counter_params)
  counter.project = original.project

  # Link participants to original agreement
  original.agreement_participants.each do |op|
    counter.agreement_participants.build(
      user: op.user,
      is_initiator: op.is_initiator,
      counter_agreement_id: original.id  # CRITICAL: Link to original
    )
  end

  if original.counter_offer!(counter)
    # Pass turn back to other party
    original.pass_turn_to_other_party(current_user)

    redirect_to agreement_path(counter), notice: "Counter offer sent!"
  else
    flash[:alert] = "Failed to create counter offer"
    render :show
  end
end

private

def counter_params
  params.require(:agreement).permit(
    :agreement_type, :payment_type, :start_date, :end_date,
    :weekly_hours, :hourly_rate, :equity_percentage,
    :tasks, milestone_ids: []
  )
end
```

**Critical Steps**:
1. Validate user has turn (`user_can_make_counter_offer?`)
2. Create new agreement with modified terms
3. Copy project reference
4. Build participants linking to **original** agreement
5. Call `counter_offer!` service method
6. Pass turn to other party
7. Redirect to new counter agreement

---

## Payment Models & Validations

**File**: `/app/models/agreement.rb` (lines 14-16, 45-46)

### Payment Type Constants

```ruby
HOURLY = "Hourly"      # Pay by hour worked
EQUITY = "Equity"      # Equity-only compensation (no cash)
HYBRID = "Hybrid"      # Hourly rate + equity percentage
```

### Conditional Validations

```ruby
validates :hourly_rate,
          presence: true,
          numericality: { greater_than_or_equal_to: 0 },
          if: -> { payment_type == HOURLY || payment_type == HYBRID }

validates :equity_percentage,
          presence: true,
          numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 },
          if: -> { payment_type == EQUITY || payment_type == HYBRID }
```

### Cost Calculation

**File**: `/app/services/agreement_calculations_service.rb`

```ruby
def total_cost
  case @agreement.payment_type
  when Agreement::HOURLY
    hourly_rate * total_hours_logged
  when Agreement::EQUITY
    0  # Equity has no immediate monetary cost
  when Agreement::HYBRID
    hourly_rate * total_hours_logged  # Equity tracked separately
  end
end

def payment_details
  {
    payment_type: @agreement.payment_type,
    hourly_rate: @agreement.hourly_rate,
    equity_percentage: @agreement.equity_percentage,
    hours_logged: total_hours_logged,
    total_cost: total_cost,
    duration_weeks: duration_in_weeks
  }
end
```

---

## Agreement Types & Validations

**File**: `/app/models/agreement.rb` (lines 3-4, 44, 48)

### Agreement Type Constants

```ruby
MENTORSHIP = "Mentorship"   # Time-bounded mentorship
CO_FOUNDER = "Co-Founder"   # Long-term partnership
```

### Type-Specific Validations

```ruby
# Mentorship requires weekly hours
validates :weekly_hours,
          presence: true,
          numericality: { greater_than: 0, less_than_or_equal_to: 40 },
          if: -> { agreement_type == MENTORSHIP }

# Mentorship requires milestones
validates :milestone_ids,
          presence: true,
          if: -> { agreement_type == MENTORSHIP }
```

### Milestone Handling

```ruby
def milestone_ids
  read_attribute(:milestone_ids) || []
end

def milestone_ids=(value)
  write_attribute(:milestone_ids, value)
end

def selected_milestones
  project.milestones.where(id: milestone_ids)
end
```

**Storage**: PostgreSQL array column

---

## Participants & Roles

**File**: `/app/models/agreement.rb` (lines 112-141)

### Participant Relationships

```ruby
belongs_to :project
has_many :agreement_participants, dependent: :destroy
has_many :users, through: :agreement_participants
```

### Helper Methods

```ruby
def initiator
  agreement_participants.find_by(is_initiator: true)&.user
end

def initiator_id
  initiator&.id
end

def other_party
  agreement_participants.find_by(is_initiator: false)&.user
end

def other_party_id
  other_party&.id
end

def participants
  agreement_participants.includes(:user)
end

def participant_for_user(user)
  agreement_participants.find_by(user: user)
end
```

### Validation

```ruby
validate :different_entrepreneur_and_mentor

def different_entrepreneur_and_mentor
  participant_users = agreement_participants.map(&:user_id)
  if participant_users.uniq.length != participant_users.length
    errors.add(:base, "Entrepreneur and mentor cannot be the same person")
  end
end
```

---

## Scopes

**File**: `/app/models/agreement.rb` (lines 52-66)

### Status Scopes

```ruby
scope :pending, -> { where(status: PENDING) }
scope :active, -> { where(status: ACCEPTED) }
scope :completed, -> { where(status: COMPLETED) }
scope :rejected, -> { where(status: REJECTED) }
scope :cancelled, -> { where(status: CANCELLED) }
scope :countered, -> { where(status: COUNTERED) }
scope :not_rejected_or_cancelled, -> { where.not(status: [REJECTED, CANCELLED]) }
```

### Type Scopes

```ruby
scope :mentorships, -> { where(agreement_type: MENTORSHIP) }
scope :co_founding, -> { where(agreement_type: CO_FOUNDER) }
```

### Performance Scopes

```ruby
scope :with_project_and_users, -> { includes(:project, agreement_participants: :user) }
scope :with_meetings, -> { includes(:meetings) }
scope :recent_first, -> { order(created_at: :desc) }
scope :for_user, ->(user_id) {
  joins(:agreement_participants).where(agreement_participants: { user_id: user_id })
}
```

### Usage Examples

```ruby
# Get all pending agreements for a user
Agreement.for_user(current_user.id).pending

# Get all active mentorships with eager loading
Agreement.mentorships.active.with_project_and_users

# Find agreements where it's user's turn
Agreement.pending.select { |a| a.whose_turn? == current_user }
```

---

## Testing Strategy

**File**: `/spec/models/agreement_spec.rb`

### State Machine Tests

```ruby
describe Agreement do
  describe 'state machine' do
    let(:project) { create(:project) }
    let(:initiator) { create(:user) }
    let(:other_party) { create(:user) }
    let(:agreement) { create(:agreement, project: project, status: Agreement::PENDING) }

    before do
      agreement.agreement_participants.create!(user: initiator, is_initiator: true)
      agreement.agreement_participants.create!(user: other_party, is_initiator: false)
    end

    it 'transitions from pending to accepted' do
      expect(agreement.status).to eq(Agreement::PENDING)

      result = agreement.accept!

      expect(result).to be_truthy
      expect(agreement.reload.status).to eq(Agreement::ACCEPTED)
    end

    it 'transitions from accepted to completed' do
      agreement.update!(status: Agreement::ACCEPTED)

      result = agreement.complete!

      expect(result).to be_truthy
      expect(agreement.reload.status).to eq(Agreement::COMPLETED)
    end

    it 'cannot accept non-pending agreement' do
      agreement.update!(status: Agreement::ACCEPTED)

      result = agreement.accept!

      expect(result).to be false
      expect(agreement.reload.status).to eq(Agreement::ACCEPTED)
    end

    it 'creates counter offer chain' do
      original = agreement
      counter = build(:agreement, project: project)

      # Link participants to original
      original.agreement_participants.each do |op|
        counter.agreement_participants.build(
          user: op.user,
          is_initiator: op.is_initiator,
          counter_agreement_id: original.id
        )
      end

      result = original.counter_offer!(counter)

      expect(result).to be_truthy
      expect(original.reload.status).to eq(Agreement::COUNTERED)
      expect(counter.status).to eq(Agreement::PENDING)
      expect(counter.counter_to).to eq(original)
      expect(original.counter_offers).to include(counter)
    end
  end
end
```

### Turn-Based System Tests

```ruby
describe 'turn-based system' do
  let(:agreement) { create(:agreement) }
  let(:initiator) { agreement.initiator }
  let(:other_party) { agreement.other_party }

  it 'sets turn to other party on creation' do
    # Initially other party's turn (recipient must act first)
    expect(agreement.whose_turn?).to eq(other_party)
  end

  it 'passes turn after counter offer' do
    agreement.agreement_participants.update_all(accept_or_counter_turn_id: other_party.id)
    expect(agreement.whose_turn?).to eq(other_party)

    # After other party counters, turn passes to initiator
    agreement.pass_turn_to_other_party(other_party)
    expect(agreement.reload.whose_turn?).to eq(initiator)
  end

  it 'checks if user can make counter offer' do
    agreement.agreement_participants.update_all(accept_or_counter_turn_id: other_party.id)

    expect(agreement.user_can_make_counter_offer?(other_party)).to be true
    expect(agreement.user_can_make_counter_offer?(initiator)).to be false
  end
end
```

### Payment Validation Tests

```ruby
describe 'payment validations' do
  it 'requires hourly_rate for HOURLY payment' do
    agreement = build(:agreement, payment_type: Agreement::HOURLY, hourly_rate: nil)

    expect(agreement).not_to be_valid
    expect(agreement.errors[:hourly_rate]).to include("must be present for hourly payment")
  end

  it 'requires equity_percentage for EQUITY payment' do
    agreement = build(:agreement, payment_type: Agreement::EQUITY, equity_percentage: nil)

    expect(agreement).not_to be_valid
    expect(agreement.errors[:equity_percentage]).to include("must be present for equity payment")
  end

  it 'requires both for HYBRID payment' do
    agreement = build(:agreement,
                     payment_type: Agreement::HYBRID,
                     hourly_rate: nil,
                     equity_percentage: nil)

    expect(agreement).not_to be_valid
    expect(agreement.errors[:hourly_rate]).to be_present
    expect(agreement.errors[:equity_percentage]).to be_present
  end
end
```

---

## Common Issues & Solutions

### Issue: "Not your turn" error

**Symptoms**: User cannot accept/counter agreement
**Root Cause**: `accept_or_counter_turn_id` points to other user
**Debug**:
```ruby
agreement.whose_turn?  # Check whose turn it is
agreement.agreement_participants.pluck(:accept_or_counter_turn_id)  # Should be same for all
```
**Fix**: Ensure turn is passed correctly after counter offer

### Issue: Counter offer not linked to original

**Symptoms**: `counter_to` returns nil, counter offers not tracked
**Root Cause**: Missing `counter_agreement_id` on participants
**Fix**: Ensure participants are built with `counter_agreement_id: original.id`

```ruby
# Correct
counter.agreement_participants.build(
  user: op.user,
  is_initiator: op.is_initiator,
  counter_agreement_id: original.id  # MUST be present
)
```

### Issue: Agreement status updated directly

**Symptoms**: Skipped business logic, inconsistent state
**Root Cause**: Direct assignment `agreement.status = ACCEPTED`
**Fix**: Always use service methods

```ruby
# Wrong ❌
agreement.update(status: Agreement::ACCEPTED)

# Right ✅
agreement.accept!
```

### Issue: Multiple counter offers appear

**Symptoms**: `counter_offers` returns duplicates
**Root Cause**: Join query without `.distinct`
**Fix**: Already handled in model (line 286)

```ruby
def counter_offers
  Agreement.joins(:agreement_participants)
          .where(agreement_participants: { counter_agreement_id: id })
          .distinct  # Prevents duplicates
end
```

---

## Related Documentation

- [Project Creation Flow](project-creation-flow.md) - Setting up projects
- [Time Tracking Workflow](time-tracking-workflow.md) - Logging hours on agreements
- [Service Layer Patterns](../architecture/service-layer-patterns.md) - Service object design
- [Multi-Database Architecture](../architecture/multi-database-architecture.md) - Database setup

---

## For AI Agents: Quick Reference

### Files to Check

- **Model**: `/app/models/agreement.rb` (311 lines)
- **Service**: `/app/services/agreement_status_service.rb` (61 lines)
- **Participant**: `/app/models/agreement_participant.rb`
- **Controller**: `/app/controllers/agreements_controller.rb`
- **Calculations Service**: `/app/services/agreement_calculations_service.rb`

### Common Tasks

**Create agreement**:
```ruby
agreement = Agreement.create!(
  project: project,
  agreement_type: Agreement::MENTORSHIP,
  payment_type: Agreement::HOURLY,
  hourly_rate: 50,
  weekly_hours: 10,
  start_date: Date.today,
  end_date: 3.months.from_now,
  tasks: "Mentorship tasks description",
  milestone_ids: [1, 2, 3]
)

# Add participants
agreement.agreement_participants.create!(
  user: initiator,
  is_initiator: true,
  accept_or_counter_turn_id: other_party.id  # Set turn to recipient
)
agreement.agreement_participants.create!(
  user: other_party,
  is_initiator: false,
  accept_or_counter_turn_id: other_party.id
)
```

**Check permissions**:
```ruby
agreement.whose_turn?                          # => User object
agreement.user_can_make_counter_offer?(user)   # => true/false
agreement.user_can_accept?(user)               # => true/false
agreement.user_can_reject?(user)               # => true/false
```

**Create counter offer**:
```ruby
original = Agreement.find(params[:id])
counter = Agreement.new(modified_params)
counter.project = original.project

original.agreement_participants.each do |op|
  counter.agreement_participants.build(
    user: op.user,
    is_initiator: op.is_initiator,
    counter_agreement_id: original.id  # Link to original
  )
end

original.counter_offer!(counter)
original.pass_turn_to_other_party(current_user)
```

**Status transitions**:
```ruby
agreement.accept!    # PENDING → ACCEPTED
agreement.reject!    # PENDING → REJECTED
agreement.cancel!    # PENDING → CANCELLED
agreement.complete!  # ACCEPTED → COMPLETED
```

**Query agreements**:
```ruby
Agreement.for_user(user.id).pending           # User's pending agreements
Agreement.for_user(user.id).active            # User's active agreements
Agreement.mentorships.active                  # All active mentorships
agreement.counter_offers                      # All counter offers to this agreement
agreement.most_recent_counter_offer           # Latest counter
```

### Decision Checklist

Before accepting agreement:
- ✅ Is status PENDING?
- ✅ Is current_user's turn?
- ✅ Is user a participant?

Before creating counter:
- ✅ Is status PENDING?
- ✅ Can user make counter offer?
- ✅ Are participants linked with counter_agreement_id?

Before completing agreement:
- ✅ Is status ACCEPTED?
- ✅ Is current_user a participant?
- ✅ Is work actually complete?
