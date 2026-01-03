# OpenAPI Documentation with rswag

**Last Updated**: 2026-01-03
**Document Type**: Development Guide
**Audience**: Developers, AI Agents

---

## Overview

FlukeBase uses [rswag](https://github.com/rswag/rswag) to generate OpenAPI 3.0 documentation from RSpec request specs. This provides:

- **Interactive API docs** via Swagger UI at `/api-docs`
- **Auto-generated OpenAPI spec** from test files
- **Request/response validation** during tests

---

## Quick Start

### View API Documentation

```bash
# Start the development server
rails server

# Open Swagger UI
open http://localhost:3006/api-docs
```

### Regenerate OpenAPI Spec

```bash
# Generate swagger/v1/swagger.yaml from specs
bundle exec rake rswag:specs:swaggerize
```

---

## File Structure

```
fluke_base/
├── config/initializers/
│   ├── rswag_api.rb          # API engine config
│   └── rswag_ui.rb           # Swagger UI config
├── spec/
│   ├── swagger_helper.rb     # OpenAPI spec definition
│   └── requests/api/v1/flukebase_connect/
│       ├── auth_spec.rb      # Authentication endpoints
│       ├── projects_spec.rb  # Projects + batch operations
│       └── memories_spec.rb  # Memories CRUD + sync
└── swagger/
    └── v1/
        └── swagger.yaml      # Generated OpenAPI spec
```

---

## Writing API Specs

### Basic Structure

```ruby
# spec/requests/api/v1/flukebase_connect/example_spec.rb
require 'swagger_helper'

RSpec.describe 'Example API', type: :request do
  path '/api/v1/flukebase_connect/example' do
    get 'List examples' do
      tags 'Examples'
      description 'Returns all examples for the authenticated user.'
      operationId 'listExamples'
      produces 'application/json'
      security [bearer_auth: []]

      response '200', 'Success' do
        schema type: :object,
               properties: {
                 examples: { type: :array, items: { type: :object } }
               }

        let(:user) { create(:user) }
        let(:api_token) { create(:api_token, user: user) }
        let(:Authorization) { "Bearer #{api_token.token}" }

        run_test!
      end

      response '401', 'Unauthorized' do
        schema '$ref' => '#/components/schemas/error'
        let(:Authorization) { nil }
        run_test!
      end
    end
  end
end
```

### Key Elements

| Element | Purpose |
|---------|---------|
| `path` | API endpoint path |
| `get/post/put/delete` | HTTP method |
| `tags` | Category for Swagger UI grouping |
| `description` | Detailed endpoint description |
| `operationId` | Unique identifier for the operation |
| `security` | Authentication requirements |
| `parameter` | Query/path/body parameters |
| `response` | Expected response with schema |
| `run_test!` | Execute the test and validate schema |

### Reusing Schemas

Define reusable schemas in `spec/swagger_helper.rb`:

```ruby
config.openapi_specs = {
  'v1/swagger.yaml' => {
    # ...
    components: {
      schemas: {
        project: {
          type: :object,
          properties: {
            id: { type: :integer },
            name: { type: :string },
            # ...
          },
          required: %w[id name]
        }
      }
    }
  }
}
```

Reference in specs:

```ruby
schema '$ref' => '#/components/schemas/project'
```

---

## Configuration

### rswag_api.rb

```ruby
Rswag::Api.configure do |c|
  c.openapi_root = Rails.root.to_s + '/swagger'
end
```

### rswag_ui.rb

```ruby
Rswag::Ui.configure do |c|
  c.openapi_endpoint '/api-docs/v1/swagger.yaml', 'FlukeBase Connect API v1'
end
```

### swagger_helper.rb

Contains the OpenAPI spec definition including:
- API info (title, version, description)
- Server URLs (production, development)
- Security schemes (bearer auth)
- Reusable component schemas

---

## Development Workflow

### Adding New Endpoints

1. **Create the spec file** in `spec/requests/api/v1/flukebase_connect/`
2. **Write the spec** with request/response examples
3. **Run the spec** to verify it passes:
   ```bash
   bundle exec rspec spec/requests/api/v1/flukebase_connect/your_spec.rb
   ```
4. **Regenerate docs**:
   ```bash
   bundle exec rake rswag:specs:swaggerize
   ```
5. **Verify in Swagger UI** at `/api-docs`

### Testing Specific Endpoints

```bash
# Run a single spec file
bundle exec rspec spec/requests/api/v1/flukebase_connect/auth_spec.rb

# Run with verbose output
bundle exec rspec spec/requests/api/v1/flukebase_connect/auth_spec.rb -fd
```

---

## Best Practices

### Documentation Quality

- Write clear, user-focused descriptions
- Include example values for parameters
- Document all possible response codes
- Use consistent naming (operationId, tags)

### Schema Definitions

- Define reusable schemas in swagger_helper.rb
- Use `$ref` to reference shared schemas
- Mark optional fields with `nullable: true`
- Include `required` arrays for mandatory fields

### Security

- All endpoints should have `security [bearer_auth: []]`
- Document required scopes in descriptions
- Test both authenticated and unauthenticated scenarios

---

## Troubleshooting

### Spec Failures

```bash
# Run with full backtrace
bundle exec rspec spec/requests/... --backtrace

# Check generated YAML
cat swagger/v1/swagger.yaml
```

### YAML Not Updating

```bash
# Force regenerate
rm swagger/v1/swagger.yaml
bundle exec rake rswag:specs:swaggerize
```

### Swagger UI Not Loading

- Verify routes are mounted: `rails routes | grep api-docs`
- Check initializer configuration
- Ensure YAML file exists in `swagger/v1/`

---

## Related Documentation

- [API Token Setup](./api-token-setup.md)
- [FlukeBase Connect API](../integrations/flukebase-connect-api.md)
- [rswag GitHub](https://github.com/rswag/rswag)
- [OpenAPI Specification](https://swagger.io/specification/)
