class AddSearchCountToUsers < ActiveRecord::Migration
  def change
    add_column :users, :search_count, :int, :default => 0
  end
end
