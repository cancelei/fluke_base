# Unified Logs Architecture

Real-time log streaming from flukebase-connect MCP sessions to the FlukeBase web dashboard.

## Overview

```
┌─────────────────────┐     HTTP/WS      ┌─────────────────────────┐
│  flukebase_connect  │ ◄───────────────►│      Rails App          │
│  (Python/FastAPI)   │                  │                         │
│  Port: 8766         │                  │  UnifiedLogsRelayJob    │
│                     │                  │         │               │
│  /api/v1/logs/*     │   poll/stream    │         ▼               │
│  /ws/logs           │ ─────────────────│  UnifiedLogsChannel     │
└─────────────────────┘                  │  (ActionCable)          │
                                         │         │               │
                                         │         ▼               │
                                         │  Browser WebSocket      │
                                         └─────────────────────────┘
```

## Components

### flukebase_connect (Python)

**HTTP Endpoints** (`/api/v1/logs/*`):
- `GET /logs/recent` - Fetch recent log entries with filtering
  - Query params: `since`, `limit`, `level`, `tool`, `session_id`
- `GET /logs/stats` - Session statistics (tool calls, tokens, success rate)
- `GET /logs/sessions` - List available log sessions

**WebSocket** (`/ws/logs`):
- Real-time log streaming
- Message types: `log_entry`, `heartbeat`, `connected`

### Rails Backend

**UnifiedLogsRelayJob** (`app/jobs/unified_logs_relay_job.rb`):
- Background job that bridges flukebase_connect to ActionCable
- Two modes:
  1. **HTTP Polling** (default): Polls `/api/v1/logs/recent` every 2 seconds
  2. **WebSocket Streaming**: Connects to `/ws/logs` for real-time updates
- Uses cache-based locking to prevent duplicate jobs
- Auto-restarts after 5 minutes for reliability

**UnifiedLogsChannel** (`app/channels/unified_logs_channel.rb`):
- ActionCable channel for browser WebSocket connections
- Broadcasts log entries to all subscribed clients

**UnifiedLogsController** (`app/controllers/unified_logs_controller.rb`):
- Serves the `/logs` page
- Requires authentication

### Frontend

**Unified Logs Page** (`app/views/unified_logs/index.html.erb`):
- Real-time log viewer with filtering
- Features:
  - Type filters (MCP, Container, App)
  - Level filter (Debug, Info, Warn, Error)
  - Search functionality
  - Auto-scroll toggle
  - Export capability

## Configuration

### Environment Variables

```bash
# flukebase_connect server location
FLUKEBASE_HTTP_URL=http://localhost:8766
FLUKEBASE_WS_URL=ws://localhost:8766/ws/logs
```

### Required Gems

```ruby
# Gemfile
gem "faye-websocket"
gem "eventmachine"
gem "solid_cable"  # ActionCable backend
```

## Starting the System

1. **Start flukebase_connect**:
   ```bash
   cd flukebase_connect
   python -m flukebase_connect --port 8766
   ```

2. **Start Rails with ActionCable**:
   ```bash
   rails server
   ```

3. **Start the relay job** (in Rails console):
   ```ruby
   # HTTP polling mode (default)
   UnifiedLogsRelayJob.perform_later

   # WebSocket mode (requires faye-websocket)
   UnifiedLogsRelayJob.perform_later(use_websocket: true)
   ```

## Data Flow

1. MCP tool calls in flukebase_connect are logged by `ConversationLogger`
2. Logs stored as JSONL files in `~/.flukebase/logs/`
3. `UnifiedLogsRelayJob` fetches logs via HTTP or subscribes via WebSocket
4. Job broadcasts entries through `UnifiedLogsChannel`
5. Browser receives updates via ActionCable WebSocket
6. Stimulus controller updates the UI in real-time

## Log Entry Format

```json
{
  "id": "uuid",
  "timestamp": "2025-12-31T08:02:19Z",
  "level": "info",
  "message": "Tool call: fb_login",
  "source": {
    "type": "mcp",
    "agent_id": "session-abc123"
  },
  "tool_name": "fb_login",
  "plugin_name": "flukebase-core",
  "duration_ms": 81,
  "tokens": 47,
  "success": true,
  "tags": []
}
```

## Troubleshooting

### "No log entries yet" / "Connecting..."
- Ensure flukebase_connect is running on port 8766
- Start the relay job: `UnifiedLogsRelayJob.perform_later`
- Check Rails logs for connection errors

### WebSocket mode not available
- Install gems: `bundle install` (faye-websocket, eventmachine)
- Falls back to HTTP polling automatically

### Logs not appearing
- Verify API endpoint: `curl http://localhost:8766/api/v1/logs/recent`
- Check ActionCable configuration in `config/cable.yml`
- Ensure SolidCable adapter is configured for development
