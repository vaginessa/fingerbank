class CreateWatchedCombinations < ActiveRecord::Migration
  def change
    create_table :watched_combinations do |t|
      t.integer :combination_id
      t.integer :user_id

      t.timestamps
    end
  end
end
