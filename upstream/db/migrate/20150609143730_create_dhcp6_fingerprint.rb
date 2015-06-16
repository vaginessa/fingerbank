class CreateDhcp6Fingerprint < ActiveRecord::Migration
  def change
    create_table :dhcp6_fingerprints do |t|
      t.string :value, :limit => 1000
      t.timestamps
    end
  end
end
