class AddOuiToTempCombinations < ActiveRecord::Migration
  def change
    add_column :temp_combinations, :oui, :string, :limit => 6
  end
end
