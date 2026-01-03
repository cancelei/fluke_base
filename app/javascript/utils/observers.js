/**
 * Common observers used across Stimulus controllers
 */

/**
 * Creates a standard IntersectionObserver for revealing elements
 * @param {Function} callback - Function to call when an element becomes visible
 * @param {Object} options - IntersectionObserver options
 * @returns {IntersectionObserver}
 */
export const createRevealObserver = (callback, options = {}) => {
  const defaultOptions = {
    root: null,
    rootMargin: '0px',
    threshold: 0.1
  };

  const finalOptions = { ...defaultOptions, ...options };

  return new IntersectionObserver((entries, observer) => {
    for (const entry of entries) {
      if (entry.isIntersecting) {
        // eslint-disable-next-line n/callback-return
        callback(entry.target);
        observer.unobserve(entry.target);
      }
    }
  }, finalOptions);
};
