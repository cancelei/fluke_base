# Agreement Negotiation Anti-Patterns & Best Practices

This document outlines anti-patterns discovered during review of the agreement negotiation flow, along with the fixes applied.

## Critical Anti-Pattern Fixed

### 1. Presenter Methods Not Honoring Turn-Based Logic

**Location:** `app/presenters/agreement_presenter.rb`

**Problem:**
The presenter methods for determining button visibility (`can_be_accepted_by?`, `can_be_rejected_by?`, `can_make_counter_offer?`) were checking only whether the user was **not the initiator** (`is_initiator: false`), rather than using the turn-based system.

**Original Code (Anti-Pattern):**
```ruby
def can_be_accepted_by?(user)
  pending? && agreement_participants.exists?(user_id: user.id, is_initiator: false)
end

def can_be_rejected_by?(user)
  pending? && agreement_participants.exists?(user_id: user.id, is_initiator: false)
end

def can_make_counter_offer?(user)
  pending? && agreement_participants.exists?(user_id: user.id, is_initiator: false)
end
```

**Why This Was Wrong:**
- The `is_initiator` field indicates who **created** the agreement, not whose **turn** it is to act
- After a counter-offer, the original initiator could still see action buttons even when it wasn't their turn
- The model already had proper turn-based methods that use `accept_or_counter_turn_id`

**Fixed Code:**
```ruby
# Turn-based negotiation methods - delegate to model's turn-based logic
def can_be_accepted_by?(user)
  object.user_can_accept?(user)
end

def can_be_rejected_by?(user)
  object.user_can_reject?(user)
end

def can_make_counter_offer?(user)
  object.user_can_make_counter_offer?(user)
end
```

**Lesson:** Always delegate authorization logic to the model's business rules rather than reimplementing them in presenters.

---

## Turn-Based Negotiation System

### How It Works

The agreement negotiation uses a turn-based system via the `accept_or_counter_turn_id` field on `AgreementParticipant`:

1. **Initial Agreement:** When Alice creates an agreement with Jack, `accept_or_counter_turn_id` is set to Jack's ID
2. **Counter Offer:** When Jack makes a counter-offer, a NEW agreement is created and `accept_or_counter_turn_id` switches to Alice's ID
3. **Each Round:** The turn always passes to the other party after any counter-offer

### Model Methods (Use These!)

```ruby
# In Agreement model
def user_can_accept?(user)
  participant = participant_for_user(user)
  participant&.can_accept_agreement?
end

def user_can_reject?(user)
  participant = participant_for_user(user)
  participant&.can_reject_agreement?
end

def user_can_make_counter_offer?(user)
  participant = participant_for_user(user)
  participant&.can_make_counter_offer?
end

# In AgreementParticipant model
def is_turn_to_act? = accept_or_counter_turn_id == user_id
def can_make_counter_offer? = is_turn_to_act? && agreement.pending?
def can_accept_agreement? = is_turn_to_act? && agreement.pending?
def can_reject_agreement? = is_turn_to_act? && agreement.pending?
```

---

## Best Practices

### 1. Single Source of Truth for Business Logic

**Do:**
- Keep authorization logic in models or policies
- Have presenters delegate to model methods
- Use Pundit policies for controller-level authorization

**Don't:**
- Reimplement business logic in presenters
- Use different conditions in views vs controllers
- Check `is_initiator` for turn-based decisions

### 2. Counter-Offer Chain Management

**Do:**
- Create a NEW agreement for each counter-offer
- Mark the original as `COUNTERED` status
- Track the chain via `counter_agreement_id` on participants

**Don't:**
- Modify the existing agreement in-place
- Lose the negotiation history
- Allow both parties to act simultaneously

### 3. Policy vs Presenter Consistency

The `AgreementPolicy` correctly uses turn-based logic:

```ruby
# app/policies/agreement_policy.rb
def accept?
  return false unless signed_in?
  return false unless participant?(user)
  record.user_can_accept?(user)  # Correct!
end
```

Ensure presenters match this behavior exactly.

---

## Testing the Negotiation Flow

### Via Rails Console

```ruby
# Check who can act
agreement = Agreement.find(id)
alice = User.find_by(first_name: "Alice")
jack = User.find_by(first_name: "Jack")

presenter = AgreementPresenter.new(agreement)
presenter.can_be_accepted_by?(alice)  # true if Alice's turn
presenter.can_be_accepted_by?(jack)   # true if Jack's turn

# Check turn
participant = agreement.participant_for_user(alice)
participant.accept_or_counter_turn_id  # Shows whose turn it is
```

### Via Browser

1. Login as the user whose turn it is
2. Navigate to Agreements > View the pending agreement
3. Verify correct buttons appear:
   - Accept Agreement (green)
   - Reject Agreement (red)
   - Counter Offer (yellow)
   - Cancel Agreement (maroon)

---

## Related Files

- `app/models/agreement.rb` - Turn-based methods
- `app/models/agreement_participant.rb` - `accept_or_counter_turn_id` field
- `app/presenters/agreement_presenter.rb` - Fixed presenter methods
- `app/policies/agreement_policy.rb` - Correct policy authorization
- `app/forms/agreement_form.rb` - Counter-offer creation logic
- `app/views/agreements/_agreement_show_actions.html.erb` - Action buttons view

---

## Verification Checklist

- [x] Jack can see Accept/Reject/Counter when it's his turn
- [x] Alice cannot see action buttons when it's Jack's turn
- [x] Counter-offer correctly switches turn to other party
- [x] Multiple rounds of counter-offers work (tested 6+ rounds)
- [x] Acceptance works and changes status to Accepted
- [x] Rejection works and changes status to Rejected
- [x] Original agreement status changes to Countered when counter-offered
