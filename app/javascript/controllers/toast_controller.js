import { Controller } from "@hotwired/stimulus"
import toastr from "toastr"

export default class extends Controller {
  static values = { 
    message: String, 
    type: String,
    title: String,
    timeout: { type: Number, default: 5000 },
    closeButton: { type: Boolean, default: true },
    progressBar: { type: Boolean, default: true },
    positionClass: { type: String, default: "toast-top-right" },
    preventDuplicates: { type: Boolean, default: true }
  }

  connect() {
    this.configureToastr()
    this.showToast()
  }

  configureToastr() {
    toastr.options = {
      closeButton: this.closeButtonValue,
      debug: false,
      newestOnTop: true,
      progressBar: this.progressBarValue,
      positionClass: this.positionClassValue,
      preventDuplicates: this.preventDuplicatesValue,
      onclick: null,
      showDuration: "300",
      hideDuration: "1000",
      timeOut: this.timeoutValue,
      extendedTimeOut: "1000",
      showEasing: "swing",
      hideEasing: "linear",
      showMethod: "fadeIn",
      hideMethod: "fadeOut"
    }
  }

  showToast() {
    if (!this.messageValue) return

    const type = this.normalizeType(this.typeValue)
    const title = this.titleValue || ""
    
    switch (type) {
      case 'success':
        toastr.success(this.messageValue, title)
        break
      case 'info':
        toastr.info(this.messageValue, title)
        break
      case 'warning':
        toastr.warning(this.messageValue, title)
        break
      case 'error':
        toastr.error(this.messageValue, title)
        break
      default:
        toastr.info(this.messageValue, title)
    }

    // Remove the element after showing the toast to prevent re-triggering
    this.element.remove()
  }

  normalizeType(type) {
    const typeMap = {
      'notice': 'success',
      'alert': 'error',
      'success': 'success',
      'error': 'error',
      'warning': 'warning',
      'info': 'info'
    }
    
    return typeMap[type] || 'info'
  }
}