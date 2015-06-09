class SetDefaultDhcp6Enterprise < ActiveRecord::Migration
  def change
    Combination.update_all(:dhcp6_enterprise_id => 0)
  end
end
