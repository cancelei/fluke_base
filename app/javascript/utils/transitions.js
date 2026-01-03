/**
 * Common transitions and animations used across Stimulus controllers
 */

/**
 * Fades out an element and removes it from the DOM
 * Uses standard Tailwind classes for compatibility with JIT
 * @param {HTMLElement} element - The element to remove
 */
export const fadeOutAndRemove = element => {
  element.classList.add('opacity-0', 'transition-opacity', 'duration-300');

  setTimeout(() => {
    element.remove();
  }, 300);
};
