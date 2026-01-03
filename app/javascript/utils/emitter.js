/**
 * Tiny event emitter for cross-controller communication.
 */
class Emitter {
  constructor() {
    this.events = new Map();
  }

  on(event, handler) {
    const handlers = this.events.get(event) || [];

    handlers.push(handler);
    this.events.set(event, handlers);

    return () => this.off(event, handler);
  }

  once(event, handler) {
    const off = this.on(event, (...args) => {
      off();
      handler(...args);
    });

    return off;
  }

  off(event, handler) {
    const handlers = this.events.get(event);

    if (!handlers) {
      return;
    }

    this.events.set(
      event,
      handlers.filter(fn => fn !== handler)
    );
  }

  emit(event, ...args) {
    const handlers = this.events.get(event);

    if (!handlers) {
      return;
    }

    handlers.forEach(fn => fn(...args));
  }
}

export const createEmitter = () => new Emitter();
export const globalEmitter = createEmitter();

// Keep a global reference for optional consumption without imports
window.FlukeEvents = globalEmitter;

export default Emitter;
