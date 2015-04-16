class AddDefaultToTimeframedRequests < ActiveRecord::Migration
  def change
    change_column :users, :timeframed_requests, :int, :default => 0
  end
end
