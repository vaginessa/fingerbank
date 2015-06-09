class AddDhcp6ToTempCombination < ActiveRecord::Migration
  def change
    add_column :temp_combinations, :dhcp6_fingerprint, :string, :limit => 1000
  end
end
