# Cloudflare Turnstile Setup Guide

This guide will help you configure Cloudflare Turnstile for your FlukeBase application.

## What is Turnstile?

Cloudflare Turnstile is a privacy-preserving alternative to CAPTCHA that helps protect your application from bots and abuse. It's free, privacy-focused, and provides a better user experience than traditional CAPTCHAs.

## Setup Steps

### 1. Get Your Turnstile Keys

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Navigate to **Turnstile** in the sidebar
3. Click **"Add site"**
4. Fill in the form:
   - **Site name**: `FlukeBase` (or your preferred name)
   - **Domain**: Your domain (e.g., `flukebase.com`, `localhost` for development)
   - **Widget mode**: Choose based on your needs:
     - **Managed**: Recommended for most use cases
     - **Non-interactive**: For invisible protection
     - **Invisible**: Completely invisible to users
5. Click **"Create"**
6. Copy the **Site Key** and **Secret Key**

### 2. Configure Environment Variables

Add these environment variables to your deployment:

```bash
# Turnstile Site Key (public key - safe to expose in frontend)
TURNSTILE_SITE_KEY=your_site_key_here

# Turnstile Secret Key (private key - keep secure)
TURNSTILE_SECRET_KEY=your_secret_key_here
```

### 3. Alternative: Use Rails Credentials

You can also store the keys in Rails credentials:

```bash
# Edit credentials
rails credentials:edit

# Add the following:
turnstile:
  site_key: your_site_key_here
  secret_key: your_secret_key_here
```

### 4. Install Dependencies

Run the following command to install the Turnstile gem:

```bash
bundle install
```

### 5. Test the Integration

1. Start your Rails server: `rails server`
2. Navigate to the signup or login page
3. You should see the Turnstile widget
4. Complete the verification and try to sign up or log in

## Configuration Options

The Turnstile widget supports various configuration options. You can modify the widget in `app/views/devise/shared/_turnstile_widget.html.erb`:

- **Theme**: `light`, `dark`, or `auto`
- **Size**: `normal`, `compact`, or `invisible`
- **Language**: Auto-detected or manually set

Example with custom options:

```erb
<div class="turnstile-widget" 
     data-sitekey="<%= Rails.application.config.turnstile[:site_key] %>" 
     data-theme="light"
     data-size="normal"
     data-callback="onTurnstileSuccess" 
     data-expired-callback="onTurnstileExpired" 
     data-error-callback="onTurnstileError">
</div>
```

## Troubleshooting

### Widget Not Showing

1. Check that `TURNSTILE_SITE_KEY` is set correctly
2. Verify the domain in your Turnstile site configuration matches your current domain
3. Check browser console for JavaScript errors

### Verification Failing

1. Check that `TURNSTILE_SECRET_KEY` is set correctly
2. Verify the secret key matches the site key in your Cloudflare dashboard
3. Check Rails logs for verification errors

### Development Environment

For local development, make sure to:
1. Add `localhost` to your Turnstile site domains
2. Use `127.0.0.1` if that's what you're using locally
3. Test with both HTTP and HTTPS if applicable

## Security Notes

- Never commit your secret key to version control
- Use environment variables or Rails credentials for production
- The site key is safe to expose in frontend code
- The secret key must be kept secure and only used on the server

## Support

- [Cloudflare Turnstile Documentation](https://developers.cloudflare.com/turnstile/)
- [Turnstile Widget Reference](https://developers.cloudflare.com/turnstile/get-started/client-side-rendering/)
