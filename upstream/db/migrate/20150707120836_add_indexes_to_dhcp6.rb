class AddIndexesToDhcp6 < ActiveRecord::Migration
  def change
    add_index :combinations, :dhcp6_fingerprint_id, :name => "combinations_dhcp6_fingerprint_id_ix"
    add_index :combinations, :dhcp6_enterprise_id, :name => "combinations_dhcp6_enterprise_id_ix"
    add_index :dhcp6_fingerprints, :value
    add_index :dhcp6_enterprises, :value
  end
end
