class AddIgnoreToDhcpFingerprints < ActiveRecord::Migration
  def change
    add_column :dhcp_fingerprints, :ignored, :boolean, :default => false
  end
end
