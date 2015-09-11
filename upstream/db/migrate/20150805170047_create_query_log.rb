class CreateQueryLog < ActiveRecord::Migration
  def change
    create_table :query_logs do |t|
      t.integer :user_id
      t.integer :combination_id
      t.timestamps
    end
  end
end
