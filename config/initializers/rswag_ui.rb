Rswag::Ui.configure do |c|
  # List the OpenAPI endpoints documented through swagger-ui.
  # Uses openapi_endpoint (v3.0+ method name)
  c.openapi_endpoint "/api-docs/v1/swagger.yaml", "FlukeBase Connect API v1"

  # Add Basic Auth in case your API is private
  # c.basic_auth_enabled = true
  # c.basic_auth_credentials 'username', 'password'
end
