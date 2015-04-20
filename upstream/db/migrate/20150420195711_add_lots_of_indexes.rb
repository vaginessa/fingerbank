class AddLotsOfIndexes < ActiveRecord::Migration
  def change
    add_index :combinations, :user_agent_id, :name => "combinations_user_agent_id_ix"
    add_index :combinations, :dhcp_fingerprint_id, :name => "combinations_dhcp_fingerprint_id_ix"
    add_index :combinations, :dhcp_vendor_id, :name => "combinations_dhcp_vendor_id_ix"
    add_index :combinations, :mac_vendor_id, :name => "combinations_mac_vendor_id_ix"
  end
end
