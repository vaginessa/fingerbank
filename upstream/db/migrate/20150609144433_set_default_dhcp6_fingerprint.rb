class SetDefaultDhcp6Fingerprint < ActiveRecord::Migration
  def change
    Combination.update_all(:dhcp6_fingerprint_id => 0)
  end
end
