# FlukeBase Agent Guidelines

## Commands
- **Single test**: `bundle exec rspec spec/path/to/file_spec.rb`
- **All tests**: `./bin/test` | **Unit**: `./bin/test --type unit` | **Integration**: `./bin/test --type integration` | **System**: `./bin/test --type system`
- **Coverage**: `./bin/test --coverage` | **Verbose**: `./bin/test --verbose`
- **Lint**: `./bin/lint` | **Auto-fix**: `./bin/lint --fix` | **CI**: `./bin/lint && ./bin/test --coverage`
- **Server**: `rails server` | **Console**: `rails console` | **Workers**: `./bin/jobs`

## Code Style
### Ruby/Rails
- Style: `rubocop-rails-omakase` | Naming: snake_case methods, CamelCase classes
- Architecture: Service objects for business logic | Error handling: Rails rescue blocks
- Imports: Rails autoloading | Delegation: `@service ||= Service.new(self)`
- Models: Concerns for shared logic | Policies: Pundit-based authorization

### JavaScript
- ES modules | Single quotes | Semicolons required | 2-space indentation
- camelCase variables/functions, PascalCase classes | Stimulus in `app/javascript/controllers/`
- Globals: Rails, Turbo, Stimulus | No console in production | Prefer const/let over var

### Architecture
- Multi-database: Primary, cache, queue, cable | Privacy: `ProjectVisibilityService`
- Real-time: Turbo streams | Unified user system with dynamic roles
- Forms: Custom form objects | Presenters: View logic separation | Queries: Complex DB logic

## Hotwire/Turbo Best Practices
### Server-Side Rendering Priority
- **HTML-over-the-wire**: Always prefer server-rendered HTML over JSON APIs
- **Turbo Drive**: Leverage automatic page navigation without full reloads
- **No client-side routing**: Keep all routing logic on the server

### Turbo Frames Usage
- **Scoped navigation**: Use `<%= turbo_frame_tag %>` for independent page segments
- **Lazy loading**: Add `src` attribute for deferred content loading
- **Parallel execution**: Break complex pages into frames for concurrent loading
- **Efficient caching**: Each frame caches independently

### Turbo Streams Patterns
- **Real-time updates**: Use `turbo_stream_from` for WebSocket connections
- **Model broadcasts**: Implement `after_create_commit { broadcast_*_to }` in models
- **Inline responses**: Use `format.turbo_stream { render turbo_stream: ... }`
- **Actions**: append, prepend, replace, update, remove, before, after

### Stimulus Integration
- **Progressive enhancement**: Add behavior to server-rendered HTML
- **Controller naming**: Use `data-controller="component-name"`
- **Targets**: Define `static targets = ["element"]` for DOM access
- **Values**: Use `static values = { key: String }` for configuration
- **Lifecycle**: Use `connect()` and `disconnect()` methods

### Form Handling
- **Turbo confirmations**: Use `data: { turbo_confirm: "Are you sure?" }`
- **Method overrides**: Use `data: { turbo_method: "delete" }` for non-GET actions
- **Error handling**: Render forms with `status: :unprocessable_entity` on validation errors
- **Progressive enhancement**: Forms work without JavaScript enabled

## Cursor Rules
- **Product**: Collaboration platform for entrepreneurs and collaborators
- **Core**: Unified user system, structured agreements, project management, time tracking
- **Tech**: Ruby on Rails + Hotwire/Turbo, PostgreSQL, Tailwind CSS, GitHub integration
- **AI**: OpenAI integration for milestone generation, progress prediction, smart matching</content>
</xai:function_call