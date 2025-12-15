import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['paymentType', 'hourlyField', 'equityField'];

  connect() {
    window.FlukeLogger?.controllerLifecycle(
      'AgreementFormController',
      'connected',
      {
        hasPaymentType: this.hasPaymentTypeTarget,
        hourlyFieldCount: this.hourlyFieldTargets.length,
        equityFieldCount: this.equityFieldTargets.length
      }
    );
    this.togglePaymentFields();
  }

  togglePaymentFields() {
    const paymentType = this.paymentTypeTargets.find(
      radio => radio.checked
    )?.value;
    const hourlyFields = this.hourlyFieldTargets;
    const equityFields = this.equityFieldTargets;

    window.FlukeLogger?.userInteraction(
      'toggled payment fields',
      this.paymentTypeTargets[0],
      {
        paymentType: paymentType || 'none',
        hourlyFieldsVisible:
          paymentType === 'Hourly' || paymentType === 'Hybrid',
        equityFieldsVisible:
          paymentType === 'Equity' || paymentType === 'Hybrid'
      }
    );

    if (paymentType === 'Hourly') {
      hourlyFields.forEach(field => {
        field.style.display = 'block';
      });
      equityFields.forEach(field => {
        field.style.display = 'none';
      });
    } else if (paymentType === 'Equity') {
      hourlyFields.forEach(field => {
        field.style.display = 'none';
      });
      equityFields.forEach(field => {
        field.style.display = 'block';
      });
    } else if (paymentType === 'Hybrid') {
      hourlyFields.forEach(field => {
        field.style.display = 'block';
      });
      equityFields.forEach(field => {
        field.style.display = 'block';
      });
    } else {
      // Default: hide all payment fields until user selects a payment type
      hourlyFields.forEach(field => {
        field.style.display = 'none';
      });
      equityFields.forEach(field => {
        field.style.display = 'none';
      });
    }
  }
}
