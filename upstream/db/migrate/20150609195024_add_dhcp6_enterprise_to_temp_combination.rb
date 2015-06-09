class AddDhcp6EnterpriseToTempCombination < ActiveRecord::Migration
  def change
    add_column :temp_combinations, :dhcp6_enterprise, :string, :limit => 1000
  end
end
