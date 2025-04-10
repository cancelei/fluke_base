class AddPaymentDetailsToAgreements < ActiveRecord::Migration[8.0]
  def change
    add_column :agreements, :payment_type, :string
    add_column :agreements, :hourly_rate, :decimal, precision: 10, scale: 2
    add_column :agreements, :equity_percentage, :decimal, precision: 5, scale: 2
    add_column :agreements, :weekly_hours, :integer
    add_column :agreements, :tasks, :text

    # Create an index on payment_type for faster queries
    add_index :agreements, :payment_type
  end
end
