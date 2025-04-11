import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="stats"
export default class extends Controller {
  static targets = ["frame"]
  
  connect() {
    this.refreshStats()
  }
  
  refreshStats() {
    // Update the stats every 30 seconds
    setInterval(() => {
      this.frameTarget.src = "/home/stats"
    }, 30000)
  }
} 