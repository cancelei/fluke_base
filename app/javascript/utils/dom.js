/**
 * DOM convenience helpers.
 */
export const qs = (root, selector) =>
  (root || document).querySelector(selector);
export const qsa = (root, selector) =>
  Array.from((root || document).querySelectorAll(selector));

export const toggleClass = (element, className, force) => {
  if (!element) {
    return;
  }
  element.classList.toggle(className, force);
};

export const setText = (element, text) => {
  if (!element) {
    return;
  }
  element.textContent = text;
};

export const safeDataset = (element, key, fallback = null) =>
  element?.dataset?.[key] ?? fallback;

export const isVisible = element => {
  if (!element) {
    return false;
  }
  const rect = element.getBoundingClientRect();

  return (
    rect.width > 0 &&
    rect.height > 0 &&
    rect.bottom >= 0 &&
    rect.right >= 0 &&
    rect.top <= (window.innerHeight || document.documentElement.clientHeight) &&
    rect.left <= (window.innerWidth || document.documentElement.clientWidth)
  );
};
