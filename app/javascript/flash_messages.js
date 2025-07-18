// This file is automatically loaded by the asset pipeline

document.addEventListener('turbo:load', () => {
  const notice = document.querySelector('[data-notice]')
  const alert = document.querySelector('[data-alert]')

  // Clear any existing toasts
  const existingContainer = document.getElementById('toast-container')
  if (existingContainer) {
    existingContainer.remove()
  }

  if (notice) {
    showToast(notice.dataset.notice, 'notice')
    notice.remove()
  }

  if (alert) {
    showToast(alert.dataset.alert, 'alert')
    alert.remove()
  }
})
