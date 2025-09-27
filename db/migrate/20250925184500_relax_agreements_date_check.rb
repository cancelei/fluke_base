class RelaxAgreementsDateCheck < ActiveRecord::Migration[8.0]
  def up
    if check_constraint_exists?(:agreements, name: "agreements_date_order_check")
      remove_check_constraint :agreements, name: "agreements_date_order_check"
    end
    add_check_constraint :agreements,
      "end_date >= start_date",
      name: "agreements_date_order_check"
  end

  def down
    if check_constraint_exists?(:agreements, name: "agreements_date_order_check")
      remove_check_constraint :agreements, name: "agreements_date_order_check"
    end
    add_check_constraint :agreements,
      "end_date > start_date",
      name: "agreements_date_order_check"
  end
end
