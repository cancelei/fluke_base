import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    toggleSidebar(event) {
        this.element.querySelector("#conversation_list").classList.toggle("active");
    }
} 