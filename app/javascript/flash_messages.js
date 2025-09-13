// Flash messages integration with toast system
// This file handles legacy flash message elements and converts them to toasts

import toastr from "toastr"

// Configure toastr globally on page load
document.addEventListener('turbo:load', () => {
  configureToastr()
  
  // Handle any legacy flash message elements that might still exist
  const notice = document.querySelector('[data-notice]')
  const alert = document.querySelector('[data-alert]')

  if (notice) {
    showToast(notice.dataset.notice, 'notice')
    notice.remove()
  }

  if (alert) {
    showToast(alert.dataset.alert, 'alert')
    alert.remove()
  }
})

function configureToastr() {
  toastr.options = {
    closeButton: true,
    debug: false,
    newestOnTop: true,
    progressBar: true,
    positionClass: "toast-top-right",
    preventDuplicates: true,
    onclick: null,
    showDuration: "300",
    hideDuration: "1000",
    timeOut: "5000",
    extendedTimeOut: "1000",
    showEasing: "swing",
    hideEasing: "linear",
    showMethod: "fadeIn",
    hideMethod: "fadeOut"
  }
}

function showToast(message, type) {
  if (!message) return

  const normalizedType = normalizeType(type)
  
  switch (normalizedType) {
    case 'success':
      toastr.success(message)
      break
    case 'error':
      toastr.error(message)
      break
    case 'warning':
      toastr.warning(message)
      break
    case 'info':
      toastr.info(message)
      break
    default:
      toastr.info(message)
  }
}

function normalizeType(type) {
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

// Export functions for external use
window.showToast = showToast
window.configureToastr = configureToastr
