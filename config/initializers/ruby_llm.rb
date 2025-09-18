RubyLLM.configure do |config|
  config.openai_api_key = ENV["OPENAI_API_KEY"]
  # Support additional providers
  config.anthropic_api_key = ENV["ANTHROPIC_API_KEY"]

  # Optional: global defaults (safe, conservative)
  # config.request_timeout = 60
  # config.proxy = ENV["HTTP_PROXY"] if ENV["HTTP_PROXY"].present?
end
