class Event < ActiveRecord::Base

  before_save :set_default_value

  def set_default_value
    self.value = 'No details provided' if self.value.nil?
  end

  def html_value
    tmp = value
    tmp.gsub! /^[ ]*$\n/, '' 
    tmp.gsub!(/\n/, '<br>')
    return tmp
  end

end
