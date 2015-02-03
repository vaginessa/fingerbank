class AddIndexesToValues < ActiveRecord::Migration
  def change
    add_index :dhcp_fingerprints, :value
    add_index :user_agents, :value
    add_index :dhcp_vendors, :value
  end
end
