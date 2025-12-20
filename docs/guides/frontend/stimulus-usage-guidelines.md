# Stimulus Usage Guidelines

**Last Updated**: 2025-12-13
**Document Type**: Guide
**Audience**: Developers, AI Agents

Keep FlukeBase's Stimulus controller count low and maintainable. Currently **23 controllers** - target: **≤30 controllers** (⚠️ approaching limit).

---

## For AI Agents

### Decision Tree: Do I need a Stimulus controller?

```
Does this feature need JavaScript?
│
├─ NO → Use HTML + CSS only ✅ STOP HERE
│   Examples: Static layouts, styled content
│
└─ YES → Can Turbo handle it?
    │
    ├─ YES → Use Turbo Drive/Frames/Streams ✅ STOP HERE
    │   Examples: Form submissions, page updates, real-time updates
    │
    └─ NO → Is it a truly interactive UI element?
        │
        ├─ NO → Reconsider if JavaScript is needed ❌
        │   Examples: Showing/hiding elements (use CSS)
        │
        └─ YES → Does a generic controller already exist?
            │
            ├─ YES → Reuse existing controller ✅
            │   Check: modal, toast, button_loading, auto_dismiss
            │
            └─ NO → Is this reusable across multiple views?
                │
                ├─ NO → Use data-action with inline handler ❌
                │   Or reconsider necessity
                │
                └─ YES → ⚠️ HALT: At 21 controllers
                    Require approval before adding more
                    - Document why Turbo cannot do this
                    - Show 3+ use cases
                    - Prove reusability
                    - Get code review approval
```

### Anti-Patterns

❌ DO NOT create controller for simple show/hide (use CSS)
❌ DO NOT create controller for form submission (use Turbo)
❌ DO NOT create controller for one-off interactions
❌ DO NOT create controller per page/feature
❌ DO NOT use Stimulus for server communication (use Turbo Streams)
❌ DO NOT duplicate logic across controllers
❌ DO NOT add more controllers without review (at 21/30 limit)
✅ DO use Turbo first, Stimulus second, vanilla JS last
✅ DO create small, focused, reusable controllers
✅ DO consolidate similar controllers
✅ DO remove unused controllers aggressively
✅ DO keep controllers under 150 lines

---

## Philosophy: Turbo First, Stimulus Last

### The Golden Rule

**"If Turbo can do it, Turbo should do it."**

Stimulus is for **client-side interactivity that cannot be handled by Turbo**.

### Priority Order

1. **HTML + CSS** - Static presentation
2. **Turbo Drive** - Full page navigation
3. **Turbo Frames** - Partial page updates
4. **Turbo Streams** - Real-time server updates
5. **Stimulus** - Client-side interactivity
6. **Vanilla JS** - Last resort only

---

## Current Controller Inventory

**Total Controllers**: 23 (target: ≤30) ⚠️ **70% of limit**

### Core Domain Controllers (7)

| Controller | Purpose | LOC | Valid? | Reusability |
|------------|---------|-----|--------|-------------|
| `time_log_controller.js` | Real-time timer with Turbo integration | ~100 | ✅ Domain-specific | Used across time tracking |
| `agreement_form_controller.js` | Dynamic agreement form fields (payment type) | ~80 | ✅ Complex logic | Agreement creation/editing |
| `milestone_ai_controller.js` | AI milestone generation with streaming | ~90 | ✅ AI integration | Milestone management |
| `conversation_controller.js` | Real-time message updates | ~70 | ✅ Messaging | Conversations |
| `message_recorder_controller.js` | Voice message recording | ~120 | ✅ MediaRecorder API | Voice messaging |
| `github_log_controller.js` | GitHub commit display logic | ~50 | ✅ GitHub integration | Commit history |
| `project_card_controller.js` | Interactive project cards | ~45 | ⚠️ Consider CSS | Project listings |

### UI/UX Controllers (8)

| Controller | Purpose | LOC | Valid? | Reusability |
|------------|---------|-----|--------|-------------|
| `modal_controller.js` | Modal dialog management | ~85 | ✅ Reusable | Used in 10+ places |
| `toast_controller.js` | Toast notifications with auto-dismiss | ~60 | ✅ Reusable | Global notifications |
| `navbar_controller.js` | Navbar interactions (mobile menu, dropdowns) | ~70 | ⚠️ Could split | Navigation |
| `theme_controller.js` | Light/dark theme toggle with persistence | ~50 | ✅ User preference | Global theme |
| `faq_controller.js` | FAQ accordion toggle | ~35 | ⚠️ Could use details/summary | FAQ page only |
| `button_loading_controller.js` | Loading state for async buttons | ~30 | ✅ Reusable | Forms, buttons |
| `auto_dismiss_controller.js` | Auto-dismiss flash messages | ~25 | ✅ Reusable | Flash messages |
| `scroll_reveal_controller.js` | Scroll-based reveal animations | ~40 | ⚠️ Marketing only | Landing page |

### Utility Controllers (6)

| Controller | Purpose | LOC | Valid? | Reusability |
|------------|---------|-----|--------|-------------|
| `timer_controller.js` | Countdown/stopwatch display | ~55 | ✅ Reusable | Time tracking |
| `clickable_row_controller.js` | Table row click navigation | ~20 | ✅ Reusable | Tables |
| `form_submission_controller.js` | Form submit handling | ~40 | ⚠️ Use Turbo | Forms |
| `scroll_into_view_controller.js` | Auto-scroll to element | ~20 | ⚠️ Could use CSS | Various |
| `skeleton_loader_controller.js` | Loading skeleton display | ~30 | ⚠️ Use Turbo Frames | Various |
| `audio_player_controller.js` | Audio playback controls | ~60 | ✅ Voice messages | Audio playback |

### Animation/Visual Controllers (2)

| Controller | Purpose | LOC | Valid? | Reusability |
|------------|---------|-----|--------|-------------|
| `stats_counter_controller.js` | Animated number counters | ~45 | ⚠️ Marketing only | Landing page |
| `stealth_mode_controller.js` | Privacy mode toggle | ~35 | ⚠️ Niche feature | Settings only |

**Analysis**:
- **21 actual controllers** (excluding `application.js`, `index.js`)
- **70% of 30 controller limit** ⚠️
- **~6 controllers** could be removed/consolidated
- **Average LOC**: ~55 lines (good, focused controllers)
- **Action Required**: Consolidation before adding new controllers

---

## Controllers for Review/Removal

### Candidates for Removal (6 controllers)

#### 1. `faq_controller.js` (35 lines)
**Current Usage**: FAQ accordion toggle

**Problem**: Can use native HTML `<details>` element

**Replacement**:
```html
<!-- Before (Stimulus) -->
<div data-controller="faq">
  <div data-faq-target="question" data-action="click->faq#toggle">Question</div>
  <div data-faq-target="answer">Answer</div>
</div>

<!-- After (HTML only) ✅ -->
<details>
  <summary>Question</summary>
  <p>Answer</p>
</details>
```

**Impact**: Used in 1 page only
**Recommendation**: ✅ Remove (save 1 controller)

---

#### 2. `form_submission_controller.js` (40 lines)
**Current Usage**: Form submit handling

**Problem**: This is exactly what Turbo Frames are for

**Replacement**:
```erb
<!-- Before (Stimulus) -->
<%= form_with model: @agreement, data: { controller: "form-submission" } do |f| %>
  <%= f.submit %>
<% end %>

<!-- After (Turbo) ✅ -->
<%= turbo_frame_tag "agreement_form" do %>
  <%= form_with model: @agreement do |f| %>
    <%= f.submit %>
  <% end %>
<% end %>
```

**Impact**: Used in 3-4 forms
**Recommendation**: ✅ Remove, migrate to Turbo (save 1 controller)

---

#### 3. `scroll_into_view_controller.js` (20 lines)
**Current Usage**: Auto-scroll to element

**Problem**: CSS `scroll-behavior: smooth` + URL hash

**Replacement**:
```css
/* CSS */
html { scroll-behavior: smooth; }
```

```html
<!-- URL navigation automatically scrolls -->
<a href="#section">Jump to section</a>
<div id="section">Content</div>
```

**Impact**: Minor convenience only
**Recommendation**: ✅ Remove (save 1 controller)

---

#### 4. `skeleton_loader_controller.js` (30 lines)
**Current Usage**: Show loading skeletons

**Problem**: Turbo Frames have built-in loading states

**Replacement**:
```erb
<!-- Before (Stimulus) -->
<div data-controller="skeleton-loader" data-skeleton-loader-loading-value="true">
  <div class="skeleton"></div>
</div>

<!-- After (Turbo Frame with loading state) ✅ -->
<%= turbo_frame_tag "content", src: content_path do %>
  <div class="skeleton-loader">Loading...</div>
<% end %>
```

**Impact**: Better handled by Turbo
**Recommendation**: ✅ Remove (save 1 controller)

---

#### 5. `scroll_reveal_controller.js` (40 lines)
**Current Usage**: Landing page scroll animations

**Problem**: IntersectionObserver or CSS-only animations

**Replacement**:
```css
/* CSS Intersection Observer approach */
@keyframes fadeIn {
  from { opacity: 0; transform: translateY(20px); }
  to { opacity: 1; transform: translateY(0); }
}

.reveal {
  view-timeline-name: --reveal;
  animation: fadeIn linear both;
  animation-timeline: --reveal;
  animation-range: entry 0% entry 100%;
}
```

**Impact**: Marketing page only
**Recommendation**: ⚠️ Consider CSS @scroll-timeline (save 1 controller)

---

#### 6. `stats_counter_controller.js` (45 lines)
**Current Usage**: Animated number counters on landing

**Problem**: Marketing feature, not core functionality

**Replacement**: CSS animation or remove feature

**Impact**: Landing page only
**Recommendation**: ⚠️ Evaluate necessity (save 1 controller)

---

### Potential Savings
Removing these 6 controllers: **21 → 15 controllers** (50% of limit) ✅

---

## Valid Controller Examples

### ✅ Excellent: Modal Controller

**Why valid**: Complex state management, reusable, cannot use Turbo

```javascript
// modal_controller.js
export default class extends Controller {
  static targets = ["container", "backdrop"]

  connect() {
    // Prevent body scroll
    document.body.style.overflow = 'hidden'

    // Close on Escape key
    this.boundHandleKeydown = this.handleKeydown.bind(this)
    document.addEventListener('keydown', this.boundHandleKeydown)
  }

  disconnect() {
    // Restore body scroll
    document.body.style.overflow = ''

    // Remove listeners
    document.removeEventListener('keydown', this.boundHandleKeydown)
  }

  close(event) {
    // Prevent closing if clicking inside modal
    if (event.target === this.backdropTarget) {
      this.element.remove()
    }
  }

  handleKeydown(event) {
    if (event.key === 'Escape') {
      this.close({ target: this.backdropTarget })
    }
  }
}
```

**Reusability**: Used in 10+ modals across app
**LOC**: 85 lines (under limit)

---

### ✅ Excellent: Time Log Controller

**Why valid**: Complex real-time timer, integrates with Turbo

```javascript
// time_log_controller.js
export default class extends Controller {
  static targets = ["display", "form"]
  static values = { running: Boolean, elapsed: Number }

  connect() {
    if (this.runningValue) {
      this.startTimer()
    }
  }

  disconnect() {
    this.stopTimer()
  }

  toggle() {
    if (this.runningValue) {
      this.stop()
    } else {
      this.start()
    }
  }

  start() {
    this.runningValue = true
    this.startTime = Date.now() - (this.elapsedValue * 1000)
    this.startTimer()

    // Update server via Turbo
    fetch(this.formTarget.action, {
      method: 'POST',
      headers: { 'Accept': 'text/vnd.turbo-stream.html' }
    })
  }

  stop() {
    this.runningValue = false
    this.stopTimer()

    // Update server via Turbo
    fetch(this.formTarget.action + '/stop', {
      method: 'POST',
      headers: { 'Accept': 'text/vnd.turbo-stream.html' }
    })
  }

  startTimer() {
    this.intervalId = setInterval(() => {
      const elapsed = (Date.now() - this.startTime) / 1000
      this.displayTarget.textContent = this.formatTime(elapsed)
    }, 1000)
  }

  stopTimer() {
    if (this.intervalId) {
      clearInterval(this.intervalId)
      this.intervalId = null
    }
  }

  formatTime(seconds) {
    const h = Math.floor(seconds / 3600)
    const m = Math.floor((seconds % 3600) / 60)
    const s = Math.floor(seconds % 60)
    return `${h}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`
  }
}
```

**Reusability**: Core time tracking feature, used throughout app
**LOC**: ~100 lines (under limit)
**Integration**: Works with Turbo Streams for server updates

---

### ✅ Good: Message Recorder Controller

**Why valid**: Browser MediaRecorder API, cannot use server-side

```javascript
// message_recorder_controller.js
export default class extends Controller {
  static targets = ["startButton", "stopButton", "audioPreview"]
  static values = { url: String }

  async connect() {
    try {
      this.stream = await navigator.mediaDevices.getUserMedia({ audio: true })
      this.mediaRecorder = new MediaRecorder(this.stream)
      this.chunks = []

      this.mediaRecorder.addEventListener('dataavailable', e => {
        this.chunks.push(e.data)
      })

      this.mediaRecorder.addEventListener('stop', () => {
        this.saveRecording()
      })
    } catch (error) {
      console.error('Microphone access denied:', error)
    }
  }

  disconnect() {
    if (this.stream) {
      this.stream.getTracks().forEach(track => track.stop())
    }
  }

  start() {
    this.chunks = []
    this.mediaRecorder.start()
    this.startButtonTarget.disabled = true
    this.stopButtonTarget.disabled = false
  }

  stop() {
    this.mediaRecorder.stop()
    this.startButtonTarget.disabled = false
    this.stopButtonTarget.disabled = true
  }

  async saveRecording() {
    const blob = new Blob(this.chunks, { type: 'audio/webm' })
    const formData = new FormData()
    formData.append('audio', blob, 'recording.webm')

    await fetch(this.urlValue, {
      method: 'POST',
      body: formData,
      headers: { 'Accept': 'text/vnd.turbo-stream.html' }
    })
  }
}
```

**Reusability**: Voice messaging feature
**LOC**: ~120 lines (acceptable for complex API)
**Browser API**: Requires MediaRecorder, getUserMedia

---

## Controller Best Practices

### Consolidation Strategy

**Before**: 3 separate controllers
```javascript
// scroll_into_view_controller.js
// scroll_reveal_controller.js
// scroll_to_top_controller.js
```

**After**: 1 unified controller
```javascript
// scroll_controller.js
export default class extends Controller {
  static values = {
    behavior: { type: String, default: 'smooth' },
    reveal: { type: Boolean, default: false },
    target: String
  }

  connect() {
    if (this.revealValue) {
      this.setupReveal()
    }
  }

  scrollTo() {
    const target = document.querySelector(this.targetValue)
    target.scrollIntoView({ behavior: this.behaviorValue })
  }

  scrollToTop() {
    window.scrollTo({ top: 0, behavior: this.behaviorValue })
  }

  setupReveal() {
    // Intersection Observer logic
  }
}
```

**Benefit**: 3 controllers → 1 controller (saves 2 controllers)

---

### Controller Size Guidelines

- **Ideal**: < 50 lines (toggle, debounce, simple interactions)
- **Acceptable**: 50-100 lines (form enhancements, loading states)
- **Review needed**: 100-200 lines (Ask: Can this be split or replaced with Turbo?)
- **Refactor required**: > 200 lines (This is definitely doing too much)

**If controller exceeds limit**:

1. **Split into focused controllers**
2. **Extract to separate modules**
3. **Move logic to server (Turbo)**

**Example**:
```javascript
// Before (180 lines) ❌
// navbar_controller.js
export default class extends Controller {
  // Mobile menu (50 lines)
  // User dropdown (40 lines)
  // Notification dropdown (50 lines)
  // Search (40 lines)
}

// After (split) ✅
// navbar_mobile_controller.js (50 lines)
// navbar_dropdown_controller.js (40 lines - reusable!)
// navbar_search_controller.js (40 lines)
```

---

### Documentation Requirements

**Every controller MUST have**:

```javascript
/**
 * Time Log Controller
 *
 * Real-time timer for tracking work time with server synchronization.
 *
 * Usage:
 *   <div data-controller="time-log"
 *        data-time-log-running-value="false"
 *        data-time-log-elapsed-value="0">
 *     <span data-time-log-target="display"></span>
 *     <button data-action="time-log#toggle">Start/Stop</button>
 *   </div>
 *
 * Targets:
 *   - display: Timer display element
 *   - form: Form for server submission
 *
 * Actions:
 *   - toggle: Start/stop timer
 *   - start: Start timer explicitly
 *   - stop: Stop timer explicitly
 *
 * Values:
 *   - running (Boolean): Whether timer is active
 *   - elapsed (Number): Elapsed seconds
 *
 * Server Integration:
 *   - Sends Turbo Stream requests on start/stop
 *   - Expects text/vnd.turbo-stream.html response
 */
export default class extends Controller {
  static targets = ["display", "form"]
  static values = { running: Boolean, elapsed: Number }

  // Implementation...
}
```

---

## Migration Plan: Reduce to 15 Controllers

### Phase 1: Remove Low-Value Controllers (Immediate)

```bash
# Remove these 4 controllers
rm app/javascript/controllers/faq_controller.js
rm app/javascript/controllers/form_submission_controller.js
rm app/javascript/controllers/scroll_into_view_controller.js
rm app/javascript/controllers/skeleton_loader_controller.js

# Update views to use native HTML/Turbo
# Run tests to ensure no breakage
```

**Result**: 21 → 17 controllers

---

### Phase 2: Consolidate Similar Controllers (Week 2)

```bash
# Consolidate navbar functionality
# navbar_controller.js → split into focused pieces
# OR move to CSS where possible

# Evaluate marketing-only controllers
# stats_counter_controller.js
# scroll_reveal_controller.js
# Either remove or justify keeping
```

**Result**: 17 → 15 controllers

---

### Phase 3: Ongoing Maintenance

**Rules**:
1. **No new controllers without removing old one** (1-in-1-out)
2. **Quarterly review** of all controllers
3. **Document reusability** for each controller
4. **Prefer Turbo** over Stimulus always

---

## Controller Approval Process

### Before Creating New Controller

**Required Documentation**:
1. **Why Turbo cannot do this** (2-3 sentences)
2. **Reusability proof** (3+ use cases)
3. **Controller size estimate** (must be <150 lines)
4. **Alternative approaches considered** (list 2+)

**Example Template**:
```markdown
## New Controller Proposal: `notification_manager_controller.js`

### Why Turbo Cannot Handle
Turbo Streams work for server-initiated updates, but this requires
client-side notification queue management with priority sorting,
deduplication, and stacking logic that cannot be done server-side.

### Reusability
1. System notifications (agreements, messages)
2. Error notifications (form validation)
3. Success notifications (CRUD actions)
4. Real-time notifications (WebSocket updates)

### Size Estimate
~80 lines (queue management, display logic, auto-dismiss)

### Alternatives Considered
1. Turbo Streams only - cannot handle client-side queue
2. Toast controller extension - would exceed 150 lines
3. Inline scripts - not reusable across 20+ places
```

**Approval Required From**:
- Tech lead review
- Confirm no existing controller can be extended

---

## Testing Stimulus Controllers

### System Tests

```ruby
# test/system/time_log_test.rb
require "application_system_test_case"

class TimeLogTest < ApplicationSystemTestCase
  test "starting timer updates display" do
    visit project_path(@project)

    # Stimulus controller loads
    assert_selector '[data-controller="time-log"]'

    # Click start
    click_button "Start Timer"

    # Timer display updates
    assert_text /\d{1,2}:\d{2}:\d{2}/  # Format: H:MM:SS

    # Running state
    assert_selector '[data-time-log-running-value="true"]'
  end

  test "stopping timer sends server request" do
    visit project_path(@project)

    click_button "Start Timer"
    sleep 2
    click_button "Stop Timer"

    # Server recorded time log
    assert TimeLog.last.duration > 0
  end
end
```

---

## Summary: Current State & Actions

### Current State
- **Controllers**: 21 actual (23 total with application/index)
- **Limit**: 30 controllers
- **Usage**: 70% of limit ⚠️
- **Action**: Consolidation required before new additions

### Immediate Actions
1. ✅ Remove 4 low-value controllers (→ 17 controllers)
2. ✅ Consolidate navbar (→ 16 controllers)
3. ✅ Review marketing controllers (→ 15 controllers)
4. ✅ Implement 1-in-1-out policy
5. ✅ Require approval for new controllers

### Target State
- **Controllers**: 15-20 controllers (50-65% of limit)
- **Average LOC**: <100 lines per controller
- **Reusability**: 100% of controllers used in 2+ places
- **Documentation**: 100% have JSDoc comments

---

## Related Documentation

- [Turbo Patterns](turbo-patterns.md) - When to use Turbo instead
- [Turbo AI Agent Guide](turbo-ai-agent-guide.md) - Turbo-first development guide
- [Ruby Coding Patterns](../../technical_spec/ruby_patterns/README.md) - Ruby 3.4.7 syntax patterns
- [Linting Guide](../development/linting.md) - Code quality and linting setup
- [Real-Time Updates](real-time-updates.md) - Turbo Streams vs Stimulus
- [Testing Strategy](../testing/integration-testing-guide.md) - Testing controllers

---

## For AI Agents: Quick Reference

### Files to Check
- **Controllers**: `/app/javascript/controllers/*.js`
- **Usage**: Search codebase for `data-controller="name"`

### Controller Count
```bash
# Count controllers (exclude application.js, index.js)
ls app/javascript/controllers/*.js | grep -v "application\|index" | wc -l

# Current: 21 controllers
# Target: 15-20 controllers
# Limit: 30 controllers
```

### Decision Checklist
⚠️ **HALT at 21 controllers - consolidation required first**

Before creating controller:
- ✅ Cannot be done with HTML/CSS?
- ✅ Cannot be done with Turbo?
- ✅ Used in 3+ places (higher bar than FeelTrack)?
- ✅ Will be <150 lines?
- ✅ No existing controller can be extended?
- ✅ Documented why necessary?
- ✅ Approved by tech lead?

### Removal Candidates
Priority order:
1. `faq_controller.js` - Use `<details>`
2. `form_submission_controller.js` - Use Turbo
3. `scroll_into_view_controller.js` - Use CSS
4. `skeleton_loader_controller.js` - Use Turbo Frames
5. `scroll_reveal_controller.js` - Use CSS @scroll-timeline
6. `stats_counter_controller.js` - Evaluate necessity
