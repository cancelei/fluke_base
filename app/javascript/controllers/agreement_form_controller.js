import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['paymentType', 'hourlyField', 'equityField', 'milestoneField', 'milestoneIds'];

  connect() {
    this.togglePaymentFields();
    // this.updateMilestoneField();
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

  updateMilestoneField() {
    // Convert NodeList of inputs to array of their values
    const selectedMilestoneIds = this.milestoneFieldTargets.map(el => el.value);

    // Get the checked value (assuming a single checkbox/input)
    const checkedValue = this.milestoneIdsTargets[0].value;

    // Toggle logic
    const index = selectedMilestoneIds.indexOf(checkedValue);
    if (index > -1) {
      selectedMilestoneIds.splice(index, 1); // Remove if exists
    } else {
      selectedMilestoneIds.push(checkedValue); // Add if not present
    }

    // Assuming you're updating a hidden field that stores this array
    // Example: <input type="hidden" data-something-target="milestoneField" />
    this.milestoneFieldTarget.value = selectedMilestoneIds.join(',');

    console.log('Updated Milestone IDs:', this.milestoneFieldTarget.value);
  }

}
