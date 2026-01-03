/**
 * Lightweight debounce and throttle utilities.
 */
export const debounce = (fn, wait = 200, { immediate = false } = {}) => {
  let timeout = null;

  return function debounced(...args) {
    const later = () => {
      timeout = null;
      if (!immediate) {
        // eslint-disable-next-line no-invalid-this
        fn.apply(this, args);
      }
    };

    const callNow = immediate && !timeout;

    clearTimeout(timeout);
    timeout = setTimeout(later, wait);

    if (callNow) {
      // eslint-disable-next-line no-invalid-this
      fn.apply(this, args);
    }
  };
};

export const throttle = (fn, wait = 200) => {
  let lastCall = 0;
  let timeout = null;

  return function throttled(...args) {
    const now = Date.now();
    const remaining = wait - (now - lastCall);

    if (remaining <= 0) {
      lastCall = now;
      // eslint-disable-next-line no-invalid-this
      fn.apply(this, args);
    } else if (!timeout) {
      timeout = setTimeout(() => {
        lastCall = Date.now();
        timeout = null;
        // eslint-disable-next-line no-invalid-this
        fn.apply(this, args);
      }, remaining);
    }
  };
};
