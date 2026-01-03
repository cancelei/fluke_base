# frozen_string_literal: true

# Connect Portal - Hub for FlukeBase Connect CLI users
# Provides download, token management, usage stats, and plugin hub
class ConnectController < ApplicationController
  before_action :authenticate_user!, except: [:install_script]
  before_action :set_connect_stats, only: [:index]

  def index
    @api_tokens = current_user.api_tokens.order(created_at: :desc)
    @recent_syncs = current_user.environment_syncs
                                .includes(:project)
                                .order(created_at: :desc)
                                .limit(10)
  end

  def download
    @install_command = generate_install_command
    @platforms = [
      { name: "macOS (Apple Silicon)", file: "fbc-macos-arm64", icon: "apple" },
      { name: "macOS (Intel)", file: "fbc-macos-x86_64", icon: "apple" },
      { name: "Linux (x86_64)", file: "fbc-linux-x86_64", icon: "linux" },
      { name: "Linux (ARM64)", file: "fbc-linux-arm64", icon: "linux" },
      { name: "Windows", file: "fbc-windows-x86_64.exe", icon: "windows" }
    ]
  end

  def quick_start
    # Generate a temporary token for quick-start flow
    @quick_token = generate_quick_start_token
    @install_command = "curl -sSL https://flukebase.com/install | sh -s -- #{@quick_token}"
  end

  def usage
    @usage_stats = calculate_usage_stats
    @time_entries = fetch_time_entries
  end

  def plugins
    @available_plugins = fetch_available_plugins
    @installed_plugins = fetch_installed_plugins
  end

  # Public endpoint - serves the install script for curl | sh
  def install_script
    render plain: install_script_content, content_type: "text/plain"
  end

  private

  def set_connect_stats
    @stats = {
      total_syncs: current_user.environment_syncs.count,
      active_projects: current_user.projects.active.count,
      api_tokens: current_user.api_tokens.active.count,
      this_week_syncs: current_user.environment_syncs
                                   .where("created_at > ?", 1.week.ago)
                                   .count
    }
  end

  def generate_install_command
    # Use pipx by default, with fallback options
    <<~COMMAND.strip
      # Option 1: Using pipx (recommended)
      pipx install flukebase-connect

      # Option 2: Using pip
      pip install --user flukebase-connect

      # Option 3: One-line install script
      curl -sSL https://flukebase.com/install | sh
    COMMAND
  end

  def generate_quick_start_token
    # Create a temporary token valid for 10 minutes
    current_user.api_tokens.create!(
      name: "Quick Start Token",
      scopes: ["connect:read", "connect:write"],
      expires_at: 10.minutes.from_now,
      quick_start: true
    ).token
  rescue StandardError
    nil
  end

  def calculate_usage_stats
    syncs = current_user.environment_syncs
    memories = current_user.memories_created_via_connect

    {
      total_syncs: syncs.count,
      syncs_this_month: syncs.where("created_at > ?", 1.month.ago).count,
      memories_stored: memories.count,
      time_tracked_minutes: calculate_time_tracked
    }
  end

  def calculate_time_tracked
    # Sum duration from time-tracking memories
    current_user.projects
                .joins(:memories)
                .where(memories: { tags: ["time-tracking"] })
                .sum("(memories.references->>'duration_minutes')::float")
                .round(1)
  rescue StandardError
    0
  end

  def fetch_time_entries
    current_user.projects
                .joins(:memories)
                .where(memories: { tags: ["time-tracking"] })
                .select("memories.*")
                .order("memories.created_at DESC")
                .limit(20)
  rescue StandardError
    []
  end

  def fetch_available_plugins
    # Hardcoded for now, could be from a registry later
    [
      {
        name: "flukebase",
        description: "Core FlukeBase integration",
        version: "1.0.0",
        installed: true
      },
      {
        name: "memory",
        description: "AI memory storage and recall",
        version: "1.0.0",
        installed: true
      },
      {
        name: "wedo",
        description: "Task management with WeDo protocol",
        version: "1.0.0",
        installed: true
      },
      {
        name: "analyzer",
        description: "Codebase analysis and metrics",
        version: "1.0.0",
        installed: true
      }
    ]
  end

  def fetch_installed_plugins
    fetch_available_plugins.select { |p| p[:installed] }
  end

  def install_script_content
    # rubocop:disable Layout/HeredocIndentation
    <<~'SCRIPT'
#!/bin/bash
# FlukeBase Connect Installer
# Usage: curl -sSL https://flukebase.com/install | sh
# Or: curl -sSL https://flukebase.com/install | sh -s -- <token>

set -e

VERSION="${FLUKEBASE_CONNECT_VERSION:-latest}"
INSTALL_DIR="${FLUKEBASE_CONNECT_HOME:-$HOME/.flukebase-connect}"
TOKEN="${1:-}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║       FlukeBase Connect Installer              ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step() {
    echo -e "${GREEN}➤${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

detect_os() {
    case "$(uname -s)" in
        Linux*)     OS=linux;;
        Darwin*)    OS=macos;;
        MINGW*|MSYS*|CYGWIN*) OS=windows;;
        *)          OS=unknown;;
    esac

    case "$(uname -m)" in
        x86_64|amd64)   ARCH=x86_64;;
        arm64|aarch64)  ARCH=arm64;;
        *)              ARCH=unknown;;
    esac

    echo "Detected: $OS ($ARCH)"
}

check_requirements() {
    print_step "Checking requirements..."

    # Check for Python 3.10+
    if command -v python3 &> /dev/null; then
        PY_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
        PY_MAJOR=$(echo $PY_VERSION | cut -d. -f1)
        PY_MINOR=$(echo $PY_VERSION | cut -d. -f2)

        if [ "$PY_MAJOR" -ge 3 ] && [ "$PY_MINOR" -ge 10 ]; then
            print_success "Python $PY_VERSION"
            HAS_PYTHON=true
        else
            print_warning "Python $PY_VERSION (3.10+ recommended)"
            HAS_PYTHON=false
        fi
    else
        print_warning "Python not found"
        HAS_PYTHON=false
    fi

    # Check for pipx or uv
    if command -v pipx &> /dev/null; then
        print_success "pipx available"
        INSTALLER="pipx"
    elif command -v uv &> /dev/null; then
        print_success "uv available"
        INSTALLER="uv"
    elif command -v pip3 &> /dev/null; then
        print_success "pip3 available"
        INSTALLER="pip"
    else
        INSTALLER="none"
    fi
}

install_with_pipx() {
    print_step "Installing with pipx..."
    pipx install flukebase-connect || pip3 install --user flukebase-connect
}

install_with_uv() {
    print_step "Installing with uv..."
    uv tool install flukebase-connect
}

install_binary() {
    print_step "Downloading pre-built binary..."

    BINARY_URL="https://github.com/flukebase/flukebase-connect/releases/download/${VERSION}/fbc-${OS}-${ARCH}"

    mkdir -p "$INSTALL_DIR/bin"

    if command -v curl &> /dev/null; then
        curl -sSL "$BINARY_URL" -o "$INSTALL_DIR/bin/fbc"
    elif command -v wget &> /dev/null; then
        wget -q "$BINARY_URL" -O "$INSTALL_DIR/bin/fbc"
    else
        print_error "Neither curl nor wget found"
        exit 1
    fi

    chmod +x "$INSTALL_DIR/bin/fbc"
    print_success "Binary installed to $INSTALL_DIR/bin/fbc"
}

setup_path() {
    print_step "Setting up PATH..."

    SHELL_RC=""
    if [ -n "$ZSH_VERSION" ] || [ -f "$HOME/.zshrc" ]; then
        SHELL_RC="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ] || [ -f "$HOME/.bashrc" ]; then
        SHELL_RC="$HOME/.bashrc"
    fi

    if [ -n "$SHELL_RC" ]; then
        PATH_LINE="export PATH=\"\$PATH:$INSTALL_DIR/bin\""
        if ! grep -q "flukebase-connect" "$SHELL_RC" 2>/dev/null; then
            echo "" >> "$SHELL_RC"
            echo "# FlukeBase Connect" >> "$SHELL_RC"
            echo "$PATH_LINE" >> "$SHELL_RC"
            print_success "Added to $SHELL_RC"
        fi
    fi
}

run_setup() {
    print_step "Running initial setup..."

    if [ -n "$TOKEN" ]; then
        fbc login --token "$TOKEN" 2>/dev/null || \
        python3 -m flukebase_connect.cli login --token "$TOKEN"
    else
        echo ""
        echo "To complete setup, run:"
        echo ""
        echo "    fbc login"
        echo ""
    fi
}

print_complete() {
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Installation Complete!${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════${NC}"
    echo ""
    echo "Commands:"
    echo "  fbc login      - Authenticate with FlukeBase"
    echo "  fbc setup      - Full setup wizard"
    echo "  fbc doctor     - Check installation health"
    echo "  fbc projects   - List your projects"
    echo ""
    echo "Documentation: https://docs.flukebase.com/connect"
    echo ""
}

main() {
    print_header
    detect_os
    check_requirements

    echo ""

    # Choose installation method
    if [ "$INSTALLER" = "pipx" ]; then
        install_with_pipx
    elif [ "$INSTALLER" = "uv" ]; then
        install_with_uv
    elif [ "$HAS_PYTHON" = true ]; then
        print_step "Installing with pip..."
        pip3 install --user flukebase-connect
    else
        install_binary
        setup_path
    fi

    run_setup
    print_complete
}

# Run main
main
    SCRIPT
    # rubocop:enable Layout/HeredocIndentation
  end
end
