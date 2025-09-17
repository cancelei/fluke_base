import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['paymentType', 'hourlyField', 'equityField'];

  connect() {
    this.togglePaymentFields();
  }

  togglePaymentFields() {
    const paymentType = this.paymentTypeTargets.find(radio => radio.checked)?.value;
    const hourlyFields = this.hourlyFieldTargets;
    const equityFields = this.equityFieldTargets;
    if (paymentType === 'Hourly') {
      hourlyFields.forEach(field => { field.style.display = 'block'; });
      equityFields.forEach(field => { field.style.display = 'none'; });
    } else if (paymentType === 'Equity') {
      hourlyFields.forEach(field => { field.style.display = 'none'; });
      equityFields.forEach(field => { field.style.display = 'block'; });
    } else if (paymentType === 'Hybrid') {
      hourlyFields.forEach(field => { field.style.display = 'block'; });
      equityFields.forEach(field => { field.style.display = 'block'; });
    } else {
      // Default: hide all payment fields until user selects a payment type
      hourlyFields.forEach(field => { field.style.display = 'none'; });
      equityFields.forEach(field => { field.style.display = 'none'; });
    }
  }

}
