class CombinationAttribute < ActiveRecord::Base

  self.abstract_class = true

  default_scope { order('value') }

  validates_uniqueness_of :value

  def self.get_or_create(vals)
    vals[:value] = vals[:value] || ''
    found = self.where(vals).first
    if found.nil?
      created = self.create(vals)
      logger.debug "#{self.to_s} not found creating with ID #{created.id}"
      return created
    else
      logger.debug "#{self.to_s} found with id #{found.id}"
      return found
    end
  end

end
