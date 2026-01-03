# Cloudflare Worker Lifecycle Management - Implementation Plan

## Overview

Rails-based orchestration layer to manage Cloudflare Browser Rendering worker lifecycle, including test execution, deployment, and resource monitoring.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Rails Application                            │
├─────────────────────────────────────────────────────────────────────┤
│  Controllers                                                         │
│  ├── Api::V1::FlukebaseConnect::BrowserTestsController              │
│  └── Api::V1::FlukebaseConnect::CloudflareWorkersController         │
├─────────────────────────────────────────────────────────────────────┤
│  Services (dry-monads Result pattern)                               │
│  ├── Cloudflare::WorkerClient          # API wrapper                │
│  ├── Cloudflare::BrowserTestRunner     # Test orchestration         │
│  ├── Cloudflare::WorkerDeployer        # Deployment management      │
│  └── Cloudflare::ResourceMonitor       # Usage/limits tracking      │
├─────────────────────────────────────────────────────────────────────┤
│  Background Jobs (Solid Queue)                                       │
│  ├── CloudflareBrowserTestJob          # Run tests async            │
│  ├── CloudflareWorkerHealthJob         # Periodic health checks     │
│  └── CloudflareUsagePollingJob         # Track usage metrics        │
├─────────────────────────────────────────────────────────────────────┤
│  Models                                                              │
│  ├── CloudflareWorker                  # Worker config & status     │
│  ├── BrowserTestRun                    # Test execution records     │
│  └── CloudflareUsageMetric             # Usage tracking             │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    Cloudflare Workers API                            │
│  ├── Workers Scripts API (deployment)                               │
│  ├── Browser Rendering API (test execution)                         │
│  └── Analytics API (usage metrics)                                  │
└─────────────────────────────────────────────────────────────────────┘
```

## Implementation Tasks

### Phase 1: Core Models & Database Schema

#### Task 1.1: Create CloudflareWorker model
- Stores worker configuration (name, account_id, script_hash)
- Tracks deployment status and last deploy timestamp
- Environment-specific settings (dev/staging/production)

```ruby
# Migration
create_table :cloudflare_workers do |t|
  t.string :name, null: false
  t.string :account_id, null: false
  t.string :script_hash
  t.string :status, default: 'unknown'  # unknown, healthy, unhealthy, deploying
  t.string :environment, default: 'development'
  t.string :worker_url
  t.datetime :last_deployed_at
  t.datetime :last_health_check_at
  t.json :configuration, default: {}
  t.timestamps
end
```

#### Task 1.2: Create BrowserTestRun model
- Records test execution requests and results
- Links to project (optional) for project-specific tests
- Stores test type, status, results, screenshots

```ruby
# Migration
create_table :browser_test_runs do |t|
  t.references :project, foreign_key: true, null: true
  t.references :cloudflare_worker, foreign_key: true
  t.references :user, foreign_key: true, null: true
  t.string :test_type, null: false  # smoke, auth, security, form, user_journey, suite
  t.string :suite_name  # for suite tests
  t.string :status, default: 'pending'  # pending, running, passed, failed, error
  t.json :results, default: {}
  t.json :assertions, default: []
  t.text :screenshot_base64
  t.integer :duration_ms
  t.datetime :started_at
  t.datetime :completed_at
  t.timestamps
end
```

#### Task 1.3: Create CloudflareUsageMetric model
- Tracks browser sessions, requests, execution time
- Daily/weekly/monthly aggregations
- Cost estimation

```ruby
# Migration
create_table :cloudflare_usage_metrics do |t|
  t.references :cloudflare_worker, foreign_key: true
  t.date :recorded_date, null: false
  t.string :period_type, default: 'daily'  # daily, weekly, monthly
  t.integer :browser_sessions, default: 0
  t.integer :requests_count, default: 0
  t.integer :execution_time_ms, default: 0
  t.decimal :estimated_cost_usd, precision: 10, scale: 4
  t.json :raw_metrics, default: {}
  t.timestamps

  t.index [:cloudflare_worker_id, :recorded_date, :period_type], unique: true
end
```

### Phase 2: Cloudflare API Client

#### Task 2.1: Create Cloudflare::WorkerClient service
Following existing patterns (HTTParty, dry-monads):

```ruby
# app/services/cloudflare/worker_client.rb
module Cloudflare
  class WorkerClient
    include Dry::Monads[:result]
    include HTTParty

    base_uri 'https://api.cloudflare.com/client/v4'

    def initialize(api_token: nil, account_id: nil)
      @api_token = api_token || ENV['CLOUDFLARE_API_TOKEN']
      @account_id = account_id || ENV['CLOUDFLARE_ACCOUNT_ID']
    end

    def get_worker(worker_name)
      # GET /accounts/:account_id/workers/scripts/:script_name
    end

    def deploy_worker(worker_name, script_content)
      # PUT /accounts/:account_id/workers/scripts/:script_name
    end

    def get_worker_settings(worker_name)
      # GET /accounts/:account_id/workers/scripts/:script_name/settings
    end

    def get_usage_analytics(worker_name, since:, until_date:)
      # GET /accounts/:account_id/workers/analytics/stored
    end
  end
end
```

#### Task 2.2: Create Cloudflare::BrowserTestRunner service
Orchestrates test execution against deployed worker:

```ruby
# app/services/cloudflare/browser_test_runner.rb
module Cloudflare
  class BrowserTestRunner
    include Dry::Monads[:result]

    ENDPOINTS = {
      smoke: '/test/smoke',
      auth: '/test/login',
      oauth: '/test/oauth-redirect',
      security_session: '/test/security/session',
      user_journey: '/test/user-journey',
      suite: ->(name) { "/test/suite/#{name}" }
    }.freeze

    def run_test(worker:, test_type:, options: {})
      # Execute test against worker URL
      # Return Success/Failure with results
    end

    def run_suite(worker:, suite_name:, options: {})
      # Execute full suite
    end
  end
end
```

### Phase 3: Background Jobs

#### Task 3.1: CloudflareBrowserTestJob
```ruby
# app/jobs/cloudflare_browser_test_job.rb
class CloudflareBrowserTestJob < ApplicationJob
  queue_as :default

  def perform(browser_test_run_id)
    test_run = BrowserTestRun.find(browser_test_run_id)
    test_run.update!(status: 'running', started_at: Time.current)

    runner = Cloudflare::BrowserTestRunner.new
    result = runner.run_test(
      worker: test_run.cloudflare_worker,
      test_type: test_run.test_type,
      options: test_run.configuration
    )

    case result
    in Success(data)
      test_run.update!(
        status: data[:passed] ? 'passed' : 'failed',
        results: data,
        assertions: data[:results],
        screenshot_base64: data[:screenshotBase64],
        duration_ms: data[:duration],
        completed_at: Time.current
      )
    in Failure(error)
      test_run.update!(
        status: 'error',
        results: { error: error.to_s },
        completed_at: Time.current
      )
    end
  end
end
```

#### Task 3.2: CloudflareWorkerHealthJob (recurring)
```ruby
# app/jobs/cloudflare_worker_health_job.rb
class CloudflareWorkerHealthJob < ApplicationJob
  queue_as :default

  def perform
    CloudflareWorker.active.find_each do |worker|
      check_health(worker)
    end
  end

  private

  def check_health(worker)
    response = HTTParty.get("#{worker.worker_url}/health", timeout: 10)
    worker.update!(
      status: response.success? ? 'healthy' : 'unhealthy',
      last_health_check_at: Time.current
    )
  rescue => e
    worker.update!(status: 'unhealthy', last_health_check_at: Time.current)
    Rails.logger.error("Worker health check failed: #{e.message}")
  end
end
```

#### Task 3.3: CloudflareUsagePollingJob (recurring)
```ruby
# app/jobs/cloudflare_usage_polling_job.rb
class CloudflareUsagePollingJob < ApplicationJob
  queue_as :low_priority

  def perform
    CloudflareWorker.active.find_each do |worker|
      Cloudflare::ResourceMonitor.new(worker).sync_usage_metrics
    end
  end
end
```

### Phase 4: API Controllers

#### Task 4.1: BrowserTestsController
```ruby
# app/controllers/api/v1/flukebase_connect/browser_tests_controller.rb
module Api::V1::FlukebaseConnect
  class BrowserTestsController < BaseController
    before_action :require_scope, only: [:create, :run_suite]

    # GET /api/v1/flukebase_connect/browser_tests
    def index
      test_runs = BrowserTestRun.where(project_id: resolved_project_ids)
                                .order(created_at: :desc)
                                .limit(params[:limit] || 50)
      render json: { test_runs: test_runs }
    end

    # POST /api/v1/flukebase_connect/browser_tests
    def create
      test_run = BrowserTestRun.create!(
        project_id: params[:project_id],
        cloudflare_worker: default_worker,
        test_type: params[:test_type],
        user: current_user,
        status: 'pending'
      )

      CloudflareBrowserTestJob.perform_later(test_run.id)

      render json: { test_run: test_run }, status: :created
    end

    # GET /api/v1/flukebase_connect/browser_tests/:id
    def show
      test_run = BrowserTestRun.find(params[:id])
      render json: { test_run: test_run }
    end

    # POST /api/v1/flukebase_connect/browser_tests/run_suite
    def run_suite
      test_run = BrowserTestRun.create!(
        project_id: params[:project_id],
        cloudflare_worker: default_worker,
        test_type: 'suite',
        suite_name: params[:suite_name] || 'smoke',
        user: current_user,
        status: 'pending'
      )

      CloudflareBrowserTestJob.perform_later(test_run.id)

      render json: { test_run: test_run }, status: :created
    end

    private

    def require_scope
      authorize_scope!('write:browser_tests')
    end

    def default_worker
      CloudflareWorker.find_by!(environment: Rails.env)
    end
  end
end
```

#### Task 4.2: CloudflareWorkersController
```ruby
# app/controllers/api/v1/flukebase_connect/cloudflare_workers_controller.rb
module Api::V1::FlukebaseConnect
  class CloudflareWorkersController < BaseController
    before_action :require_admin_scope, only: [:deploy, :update]

    # GET /api/v1/flukebase_connect/cloudflare_workers
    def index
      workers = CloudflareWorker.all
      render json: { workers: workers }
    end

    # GET /api/v1/flukebase_connect/cloudflare_workers/:id
    def show
      worker = CloudflareWorker.find(params[:id])
      render json: {
        worker: worker,
        health: worker.status,
        usage_today: worker.usage_metrics.where(recorded_date: Date.current).first
      }
    end

    # GET /api/v1/flukebase_connect/cloudflare_workers/:id/usage
    def usage
      worker = CloudflareWorker.find(params[:id])
      metrics = worker.usage_metrics
                      .where(recorded_date: params[:since]..params[:until])
                      .order(recorded_date: :desc)
      render json: { metrics: metrics }
    end

    # POST /api/v1/flukebase_connect/cloudflare_workers/:id/health_check
    def health_check
      worker = CloudflareWorker.find(params[:id])
      result = Cloudflare::ResourceMonitor.new(worker).check_health

      render json: {
        worker_id: worker.id,
        status: worker.reload.status,
        checked_at: worker.last_health_check_at
      }
    end

    private

    def require_admin_scope
      authorize_scope!('admin:cloudflare')
    end
  end
end
```

### Phase 5: Resource Monitoring

#### Task 5.1: Create Cloudflare::ResourceMonitor service
```ruby
# app/services/cloudflare/resource_monitor.rb
module Cloudflare
  class ResourceMonitor
    include Dry::Monads[:result]

    USAGE_WARNING_THRESHOLD = 0.85  # 85% like existing patterns

    def initialize(worker)
      @worker = worker
      @client = WorkerClient.new
    end

    def check_health
      response = HTTParty.get("#{@worker.worker_url}/health", timeout: 10)
      status = response.success? ? 'healthy' : 'unhealthy'
      @worker.update!(status: status, last_health_check_at: Time.current)
      Success(status)
    rescue => e
      @worker.update!(status: 'unhealthy', last_health_check_at: Time.current)
      Failure(e.message)
    end

    def check_limits
      response = HTTParty.get("#{@worker.worker_url}/limits", timeout: 10)
      return Failure('Failed to fetch limits') unless response.success?

      limits = response.parsed_response
      warn_if_approaching_limits(limits)
      Success(limits)
    end

    def sync_usage_metrics
      result = @client.get_usage_analytics(
        @worker.name,
        since: Date.yesterday,
        until_date: Date.current
      )

      case result
      in Success(data)
        persist_metrics(data)
      in Failure(error)
        Rails.logger.error("Failed to sync metrics: #{error}")
      end
    end

    private

    def warn_if_approaching_limits(limits)
      return unless limits['active_sessions'] && limits['max_sessions']

      usage_ratio = limits['active_sessions'].to_f / limits['max_sessions']
      if usage_ratio >= USAGE_WARNING_THRESHOLD
        Rails.logger.warn(
          "Cloudflare browser sessions at #{(usage_ratio * 100).round}% capacity"
        )
        # Could trigger notification here
      end
    end

    def persist_metrics(data)
      CloudflareUsageMetric.upsert(
        {
          cloudflare_worker_id: @worker.id,
          recorded_date: Date.current,
          period_type: 'daily',
          browser_sessions: data['sessions'] || 0,
          requests_count: data['requests'] || 0,
          execution_time_ms: data['cpu_time'] || 0,
          raw_metrics: data
        },
        unique_by: [:cloudflare_worker_id, :recorded_date, :period_type]
      )
    end
  end
end
```

### Phase 6: Recurring Jobs Configuration

#### Task 6.1: Update config/recurring.yml
```yaml
# Add to existing recurring.yml
cloudflare_worker_health:
  class: CloudflareWorkerHealthJob
  schedule: every 5 minutes

cloudflare_usage_polling:
  class: CloudflareUsagePollingJob
  schedule: every hour
```

### Phase 7: API Token Scopes

#### Task 7.1: Add new scopes to ApiToken model
```ruby
# Add to ApiToken::VALID_SCOPES
'read:browser_tests'    # View test runs and results
'write:browser_tests'   # Trigger test runs
'read:cloudflare'       # View worker status and usage
'admin:cloudflare'      # Deploy/manage workers
```

### Phase 8: Routes

#### Task 8.1: Add routes
```ruby
# config/routes.rb - in api/v1/flukebase_connect namespace
resources :browser_tests, only: [:index, :show, :create] do
  collection do
    post :run_suite
  end
end

resources :cloudflare_workers, only: [:index, :show] do
  member do
    get :usage
    post :health_check
  end
end
```

## File Summary

| File | Purpose |
|------|---------|
| `db/migrate/xxx_create_cloudflare_workers.rb` | Worker model migration |
| `db/migrate/xxx_create_browser_test_runs.rb` | Test runs migration |
| `db/migrate/xxx_create_cloudflare_usage_metrics.rb` | Usage metrics migration |
| `app/models/cloudflare_worker.rb` | Worker configuration model |
| `app/models/browser_test_run.rb` | Test execution records |
| `app/models/cloudflare_usage_metric.rb` | Usage tracking model |
| `app/services/cloudflare/worker_client.rb` | Cloudflare API client |
| `app/services/cloudflare/browser_test_runner.rb` | Test orchestration |
| `app/services/cloudflare/resource_monitor.rb` | Health & usage monitoring |
| `app/jobs/cloudflare_browser_test_job.rb` | Async test execution |
| `app/jobs/cloudflare_worker_health_job.rb` | Recurring health checks |
| `app/jobs/cloudflare_usage_polling_job.rb` | Recurring usage sync |
| `app/controllers/api/v1/flukebase_connect/browser_tests_controller.rb` | Test API |
| `app/controllers/api/v1/flukebase_connect/cloudflare_workers_controller.rb` | Worker API |
| `spec/` | Corresponding test files |

## Patterns Applied

1. **dry-monads Result types** - All services return Success/Failure
2. **HTTParty base_uri** - Consistent API client pattern
3. **Solid Queue jobs** - Background processing with queues
4. **85% threshold warnings** - Rate limit monitoring pattern
5. **Scope-based authorization** - API token permissions
6. **ENV-first configuration** - Cloudflare credentials from environment
7. **Upsert for metrics** - Idempotent usage tracking

## Dependencies

- No new gems required (uses existing dry-monads, httparty)
- Cloudflare API Token with:
  - Workers Scripts Read/Write
  - Workers Analytics Read
  - Account Analytics Read

## Estimated Scope

- 3 new models with migrations
- 3 new services following existing patterns
- 3 new background jobs
- 2 new API controllers
- Route additions
- Test coverage for all new code
