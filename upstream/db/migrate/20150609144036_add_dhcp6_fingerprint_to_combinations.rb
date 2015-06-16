class AddDhcp6FingerprintToCombinations < ActiveRecord::Migration
  def change
    add_column :combinations, :dhcp6_fingerprint_id, :integer
  end
end
