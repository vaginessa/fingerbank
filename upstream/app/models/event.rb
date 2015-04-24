class Event < ActiveRecord::Base

  before_save :set_default_value

  def set_default_value
    self.value = 'No details provided' if self.value.nil?
  end


end
