import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['paymentType', 'hourlyField', 'equityField']

  connect() {
    this.togglePaymentFields()
  }

  togglePaymentFields() {
//     const paymentType = this.paymentTypeTargets.find(radio => radio.checked)?.value
//     const hourlyFields = this.hourlyFieldTargets
//     const equityFields = this.equityFieldTargets
// console.log(`Payment Type: ${paymentType}`)
//     if (paymentType === 'Hourly') {
//       hourlyFields.forEach(field => field.style.display = 'block')
//       equityFields.forEach(field => field.style.display = 'none')
//     } else if (paymentType === 'Equity') {
//       hourlyFields.forEach(field => field.style.display = 'none')
//       equityFields.forEach(field => field.style.display = 'block')
//     } else if (paymentType === 'Hybrid') {
//       hourlyFields.forEach(field => field.style.display = 'block')
//       equityFields.forEach(field => field.style.display = 'block')
//     } else {
//       // Default: hide all payment fields until user selects a payment type
//       hourlyFields.forEach(field => field.style.display = 'none')
//       equityFields.forEach(field => field.style.display = 'none')
//     }

    document.addEventListener("turbo:load", function () {
          document.querySelector('#agreement_payment_type_hourly').checked = true;
          hideShowPaymentFields("Hourly");
          document.querySelectorAll('input[type="radio"]').forEach(radio => {
          radio.addEventListener('change', function() {
          let selectedValue = this.value;
          console.log(selectedValue);
          hideShowPaymentFields(selectedValue);
        });
      });
    });
  }

  hideShowPaymentFields(selectedValue){
    let hourlyField = document.querySelector('.hourly-field');
    let equityField = document.querySelector('.equity-field');
  
    if (selectedValue === 'Hourly') {
      if (hourlyField) hourlyField.style.display = 'block';
      if (equityField) equityField.style.display = 'none';
    } else if (selectedValue === 'Equity') {
      if (hourlyField) hourlyField.style.display = 'none';
      if (equityField) equityField.style.display = 'block';
    } else if (selectedValue === 'Hybrid') {
      if (hourlyField) hourlyField.style.display = 'block';
      if (equityField) equityField.style.display = 'block';
    }
  }
} 