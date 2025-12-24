# frozen_string_literal: true

# Provides URL normalization utilities for stripping tracking parameters
# and cleaning URLs for storage.
#
# Usage:
#   include UrlNormalizable
#   normalized_url = normalize_url_for_storage("example.com?utm_source=google")
#   # => "example.com"
#
module UrlNormalizable
  extend ActiveSupport::Concern

  # Common tracking and marketing parameters to strip from URLs
  TRACKING_PARAMS = %w[
    utm_source utm_medium utm_campaign utm_term utm_content utm_id
    fbclid gclid gclsrc dclid
    msclkid twclid li_fat_id
    mc_cid mc_eid _hsenc _hsmi
    ref ref_src
    _ga _gl yclid igshid
  ].freeze

  # Normalizes a URL for storage by:
  # - Stripping http:// or https:// protocol
  # - Removing known tracking/marketing parameters
  # - Removing trailing slashes
  #
  # @param url [String] The URL to normalize
  # @return [String, nil] The normalized URL or nil if blank
  def normalize_url_for_storage(url)
    return nil if url.blank?

    url = url.to_s.strip
    url = strip_protocol(url)
    url = strip_tracking_params(url)
    url = strip_trailing_slashes(url)
    url.presence
  end

  private

  def strip_protocol(url)
    url.gsub(%r{^https?://}i, "")
  end

  def strip_trailing_slashes(url)
    url.gsub(%r{/+$}, "")
  end

  # Strips known tracking parameters from a URL while preserving
  # legitimate query parameters.
  #
  # @param url [String] URL without protocol (e.g., "example.com/page?foo=bar")
  # @return [String] URL with tracking params removed
  def strip_tracking_params(url)
    # Add protocol temporarily for URI parsing
    uri = URI.parse("https://#{url}")
    return url unless uri.query.present?

    # Parse and filter query parameters
    params = URI.decode_www_form(uri.query)
    clean_params = params.reject { |key, _| tracking_param?(key) }

    # Rebuild the URL without tracking params
    uri.query = clean_params.empty? ? nil : URI.encode_www_form(clean_params)
    uri.to_s.gsub(%r{^https://}, "")
  rescue URI::InvalidURIError
    # If URL parsing fails, return the original
    url
  end

  def tracking_param?(key)
    TRACKING_PARAMS.include?(key.downcase)
  end
end
