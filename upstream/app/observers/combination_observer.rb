class CombinationObserver < ActiveRecord::Observer
  observe Combination

  def after_save(object)
    Rails.cache.delete("views/combination-row-#{object.id}")
  end
end
