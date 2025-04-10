import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['paymentType', 'hourlyField', 'equityField']

  connect() {
    this.togglePaymentFields()
  }

  togglePaymentFields() {
    const paymentType = this.paymentTypeTargets.find(radio => radio.checked)?.value
    const hourlyFields = this.hourlyFieldTargets
    const equityFields = this.equityFieldTargets

    if (paymentType === 'hourly') {
      hourlyFields.forEach(field => field.style.display = 'block')
      equityFields.forEach(field => field.style.display = 'none')
    } else if (paymentType === 'equity') {
      hourlyFields.forEach(field => field.style.display = 'none')
      equityFields.forEach(field => field.style.display = 'block')
    } else if (paymentType === 'hybrid') {
      hourlyFields.forEach(field => field.style.display = 'block')
      equityFields.forEach(field => field.style.display = 'block')
    } else {
      // Default: hide all payment fields until user selects a payment type
      hourlyFields.forEach(field => field.style.display = 'none')
      equityFields.forEach(field => field.style.display = 'none')
    }
  }
} 