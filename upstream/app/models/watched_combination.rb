class WatchedCombination < ActiveRecord::Base

  belongs_to :user
  belongs_to :combination

end
