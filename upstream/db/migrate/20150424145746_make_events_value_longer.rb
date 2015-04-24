class MakeEventsValueLonger < ActiveRecord::Migration
  def change
    change_column :events, :value, :text, :limit => 4294967295
  end
end
