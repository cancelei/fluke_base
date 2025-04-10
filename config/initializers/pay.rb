Pay.setup do |config|
  # For use in the receipt/refund/renewal mailers
  config.business_name = "FlukeBase"
  config.business_address = "123 Business Street"
  config.application_name = "FlukeBase"
  config.support_email = "support@example.com"

  config.default_product_name = "FlukeBase Service"
  config.default_plan_name = "Mentorship"

  # Stripe configuration
  # config.enabled_processors = [:stripe]
  # config.default_processor = :stripe

  # All processors are enabled by default. If you don't have the credentials for a processor, disable it here.
  config.enabled_processors = []
end
