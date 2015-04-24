class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.text :value
      t.timestamps
    end
  end
end
