import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['element'];

  connect() {
    this.setupIntersectionObserver();
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect();
    }
  }

  setupIntersectionObserver() {
    const options = {
      root: null,
      rootMargin: '-100px',
      threshold: 0.1
    };

    this.observer = new IntersectionObserver((entries) => {
      entries.forEach((entry, _index) => {
        if (entry.isIntersecting) {
          // Add staggered delay for multiple elements
          const delay = Array.from(this.elementTargets).indexOf(entry.target) * 100;

          setTimeout(() => {
            this.revealElement(entry.target);
          }, delay);

          this.observer.unobserve(entry.target);
        }
      });
    }, options);

    // Initially hide all elements and observe them
    this.elementTargets.forEach(element => {
      element.style.opacity = '0';
      element.style.transform = 'translateY(50px)';
      element.style.transition = 'all 0.8s cubic-bezier(0.25, 0.46, 0.45, 0.94)';

      this.observer.observe(element);
    });
  }

  revealElement(element) {
    element.style.opacity = '1';
    element.style.transform = 'translateY(0)';

    // Add a subtle bounce effect
    setTimeout(() => {
      element.style.transform = 'translateY(-5px)';
      setTimeout(() => {
        element.style.transform = 'translateY(0)';
      }, 150);
    }, 400);
  }

  showDemo(event) {
    event.preventDefault();

    // Create demo modal
    const modal = document.createElement('div');
    modal.className = 'fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-75 p-4';
    modal.innerHTML = `
      <div class="bg-white rounded-3xl p-8 max-w-4xl w-full max-h-[90vh] overflow-y-auto">
        <div class="flex justify-between items-center mb-8">
          <div>
            <h3 class="text-3xl font-bold text-gray-900">See FlukeBase in Action</h3>
            <p class="text-gray-600 mt-2">Watch how we connect entrepreneurs, mentors, and co-founders</p>
          </div>
          <button class="text-gray-400 hover:text-gray-600 p-2" data-action="click->scroll-reveal#closeDemo">
            <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
            </svg>
          </button>
        </div>
        
        <div class="aspect-video bg-gradient-to-br from-blue-500 to-purple-600 rounded-2xl flex items-center justify-center mb-8 relative overflow-hidden">
          <div class="absolute inset-0 bg-black bg-opacity-20"></div>
          <div class="relative z-10 text-center text-white">
            <div class="w-20 h-20 bg-white bg-opacity-20 backdrop-blur-sm rounded-full flex items-center justify-center mx-auto mb-4 cursor-pointer hover:bg-opacity-30 transition-all">
              <svg class="w-10 h-10 text-white" fill="currentColor" viewBox="0 0 20 20">
                <path d="M8 5v10l8-5-8-5z"/>
              </svg>
            </div>
            <p class="text-xl font-semibold mb-2">Interactive Demo</p>
            <p class="text-blue-100">Click to start the 2-minute walkthrough</p>
          </div>
        </div>
        
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div class="text-center p-4 bg-blue-50 rounded-xl">
            <div class="w-12 h-12 bg-blue-500 rounded-lg flex items-center justify-center mx-auto mb-3">
              <svg class="w-6 h-6 text-white" fill="currentColor" viewBox="0 0 20 20">
                <path d="M13 6a3 3 0 11-6 0 3 3 0 016 0zM18 8a2 2 0 11-4 0 2 2 0 014 0zM14 15a4 4 0 00-8 0v3h8v-3z"/>
              </svg>
            </div>
            <h4 class="font-semibold text-gray-900 mb-2">Smart Matching</h4>
            <p class="text-sm text-gray-600">See how our AI finds perfect matches</p>
          </div>
          
          <div class="text-center p-4 bg-green-50 rounded-xl">
            <div class="w-12 h-12 bg-green-500 rounded-lg flex items-center justify-center mx-auto mb-3">
              <svg class="w-6 h-6 text-white" fill="currentColor" viewBox="0 0 20 20">
                <path d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
              </svg>
            </div>
            <h4 class="font-semibold text-gray-900 mb-2">Agreements</h4>
            <p class="text-sm text-gray-600">Explore our structured agreement system</p>
          </div>
          
          <div class="text-center p-4 bg-purple-50 rounded-xl">
            <div class="w-12 h-12 bg-purple-500 rounded-lg flex items-center justify-center mx-auto mb-3">
              <svg class="w-6 h-6 text-white" fill="currentColor" viewBox="0 0 20 20">
                <path d="M2 10a8 8 0 018-8v8h8a8 8 0 11-16 0z"/>
              </svg>
            </div>
            <h4 class="font-semibold text-gray-900 mb-2">Progress Tracking</h4>
            <p class="text-sm text-gray-600">Track milestones and performance</p>
          </div>
        </div>
      </div>
    `;

    document.body.appendChild(modal);
    document.body.style.overflow = 'hidden';

    // Animate modal entrance
    modal.style.opacity = '0';
    requestAnimationFrame(() => {
      modal.style.transition = 'opacity 0.3s ease-out';
      modal.style.opacity = '1';
    });
  }

  closeDemo(event) {
    const modal = event.target.closest('.fixed');
    if (modal) {
      modal.style.opacity = '0';
      setTimeout(() => {
        if (modal.parentNode) {
          document.body.removeChild(modal);
        }
        document.body.style.overflow = 'auto';
      }, 300);
    }
  }
}
