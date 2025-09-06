# This initializer configures active_record_doctor to ignore specific warnings
# about models referencing non-existent tables from external gems

if defined?(ActiveRecordDoctor)
  # Create a configuration file for active_record_doctor
  # This will suppress warnings about models from external gems that reference tables
  # that don't exist in your database

  # List of models to ignore in undefined_table_references detector
  ignored_models = [
    "ActionMailbox::InboundEmail",
    "ActionText::EncryptedRichText",
    "ActionText::RichText",
    "Pay::Charge",
    "Pay::Customer",
    "Pay::Merchant",
    "Pay::PaymentMethod",
    "Pay::Subscription",
    "Pay::Webhook",
    "SolidCache::Entry"
  ]

  # Write the configuration to a YAML file if it doesn't exist
  config_path = Rails.root.join("config", "active_record_doctor.yml")
  unless File.exist?(config_path)
    require "yaml"

    config = {
      "detectors" => {
        "undefined_table_references" => {
          "ignore" => ignored_models
        }
      }
    }

    File.write(config_path, config.to_yaml)
    puts "Created active_record_doctor configuration at #{config_path}"
  end
end
