class FingerbankModel < ActiveRecord::Base
  self.abstract_class = true
  def self.search(what, on)
    what = "%#{what}%"
    where("#{on} LIKE ?", what)
  end
end
