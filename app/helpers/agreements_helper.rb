module AgreementsHelper
  def fetch_initiator_data(meta)
    return unless meta.present?

    name = User.find_by_id(meta["id"]).full_name
    role = meta["role"]
    [ name, role ]
  end
end
