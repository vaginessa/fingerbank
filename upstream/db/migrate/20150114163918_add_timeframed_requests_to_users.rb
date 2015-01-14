class AddTimeframedRequestsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :timeframed_requests, :integer
  end
end
