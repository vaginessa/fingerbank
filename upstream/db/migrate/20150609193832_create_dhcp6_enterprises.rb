class CreateDhcp6Enterprises < ActiveRecord::Migration
  def change
    create_table :dhcp6_enterprises do |t|
      t.string :value, limit: 1000

      t.timestamps
    end
    add_column :combinations, :dhcp6_enterprise_id, :integer
  end
end
