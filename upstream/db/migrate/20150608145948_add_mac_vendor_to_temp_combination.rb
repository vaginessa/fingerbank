class AddMacVendorToTempCombination < ActiveRecord::Migration
  def change
    add_column :temp_combinations, :mac_vendor, :string, :limit => 1000
  end
end
