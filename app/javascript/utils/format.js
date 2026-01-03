/**
 * Formatting utilities for FlukeBase.
 * Provides consistent formatting for durations, currency, and relative times.
 * @module utils/format
 */

/**
 * Format seconds into HH:MM:SS duration string.
 * @param {number} seconds - Duration in seconds (can be null/undefined)
 * @returns {string} Formatted duration string like "01:30:45"
 * @example
 * formatDuration(3661) // "01:01:01"
 * formatDuration(90)   // "00:01:30"
 * formatDuration(null) // "00:00:00"
 */
export const formatDuration = seconds => {
  const totalSeconds = Math.max(0, Math.floor(seconds || 0));
  const hours = Math.floor(totalSeconds / 3600);
  const minutes = Math.floor((totalSeconds % 3600) / 60);
  const remainingSeconds = totalSeconds % 60;

  return `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}:${String(remainingSeconds).padStart(2, '0')}`;
};

/**
 * Format seconds into a human-readable time string (M:SS or H:MM:SS).
 * @param {number} seconds - Total seconds
 * @returns {string} Formatted string like "1:30" or "1:15:30"
 * @example
 * formatTime(90)   // "1:30"
 * formatTime(3661) // "1:01:01"
 */
export const formatTime = seconds => {
  const totalSeconds = Math.max(0, Math.floor(seconds || 0));
  const hours = Math.floor(totalSeconds / 3600);
  const minutes = Math.floor((totalSeconds % 3600) / 60);
  const remainingSeconds = totalSeconds % 60;

  const paddedSeconds = String(remainingSeconds).padStart(2, '0');

  if (hours > 0) {
    const paddedMinutes = String(minutes).padStart(2, '0');

    return `${hours}:${paddedMinutes}:${paddedSeconds}`;
  }

  return `${minutes}:${paddedSeconds}`;
};

/**
 * Format a number as currency using Intl.NumberFormat.
 * @param {number|string} value - The value to format
 * @param {string} [currency='USD'] - ISO 4217 currency code
 * @param {string} [locale='en-US'] - BCP 47 locale identifier
 * @returns {string} Formatted currency string
 * @example
 * formatCurrency(1234.56)           // "$1,234.56"
 * formatCurrency(1000, 'EUR', 'de') // "1.000,00 €"
 */
export const formatCurrency = (value, currency = 'USD', locale = 'en-US') => {
  const number = Number(value) || 0;

  return new Intl.NumberFormat(locale, {
    style: 'currency',
    currency,
    maximumFractionDigits: 2
  }).format(number);
};

/**
 * Format a date as relative time (e.g., "2 days ago", "in 3 hours").
 * @param {Date|string} date - The date to format (Date object or ISO string)
 * @param {string} [locale='en'] - BCP 47 locale identifier
 * @returns {string} Human-readable relative time string
 * @example
 * formatRelativeTime(new Date(Date.now() - 86400000)) // "yesterday"
 * formatRelativeTime('2024-01-01T00:00:00Z')          // "3 months ago"
 */
export const formatRelativeTime = (date, locale = 'en') => {
  if (!date) {
    return '';
  }
  const target = typeof date === 'string' ? new Date(date) : date;
  const diffMs = target.getTime() - Date.now();
  const diffSeconds = Math.round(diffMs / 1000);

  const divisions = [
    { amount: 60, name: 'second' },
    { amount: 60, name: 'minute' },
    { amount: 24, name: 'hour' },
    { amount: 7, name: 'day' },
    { amount: 4.34524, name: 'week' },
    { amount: 12, name: 'month' },
    { amount: Number.POSITIVE_INFINITY, name: 'year' }
  ];

  let duration = diffSeconds;
  let unit = 'second';

  for (const division of divisions) {
    if (Math.abs(duration) < division.amount) {
      unit = division.name;
      break;
    }
    duration /= division.amount;
  }

  return new Intl.RelativeTimeFormat(locale, { numeric: 'auto' }).format(
    Math.round(duration),
    unit
  );
};
