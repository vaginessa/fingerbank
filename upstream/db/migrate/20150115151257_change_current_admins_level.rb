class ChangeCurrentAdminsLevel < ActiveRecord::Migration
  def change
    User.where(:level => 1).update_all(:level => User.LEVELS[:admin])
  end
end
