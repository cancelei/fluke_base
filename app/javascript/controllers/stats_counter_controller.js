import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['card', 'number'];

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
      rootMargin: '0px',
      threshold: 0.3
    };

    this.observer = new IntersectionObserver(entries => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          this.animateCards();
          this.observer.unobserve(entry.target);
        }
      });
    }, options);

    this.observer.observe(this.element);
  }

  animateCards() {
    // Animate the cards appearing
    this.cardTargets.forEach((card, index) => {
      setTimeout(() => {
        card.style.opacity = '0';
        card.style.transform = 'translateY(40px)';
        card.style.transition = 'all 0.6s cubic-bezier(0.25, 0.46, 0.45, 0.94)';

        requestAnimationFrame(() => {
          card.style.opacity = '1';
          card.style.transform = 'translateY(0)';
        });
      }, index * 150);
    });

    // Animate the numbers counting up
    setTimeout(() => {
      this.animateNumbers();
    }, 300);
  }

  animateNumbers() {
    this.numberTargets.forEach(target => {
      const endValue = parseInt(target.dataset.endValue) || 100;
      const duration = 2000;
      const startValue = 0;

      this.animateNumber(target, startValue, endValue, duration);
    });
  }

  animateNumber(element, start, end, duration) {
    const startTime = performance.now();

    const updateNumber = currentTime => {
      const elapsed = currentTime - startTime;
      const progress = Math.min(elapsed / duration, 1);

      // Use easing function for smoother animation
      const easeOutExpo = progress === 1 ? 1 : 1 - 2 ** (-10 * progress);
      const currentValue = Math.round(start + (end - start) * easeOutExpo);

      element.textContent = currentValue;

      if (progress < 1) {
        requestAnimationFrame(updateNumber);
      }
    };

    requestAnimationFrame(updateNumber);
  }
}
