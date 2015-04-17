require 'combination/detection'

class Combination < FingerbankModel
  belongs_to :dhcp_fingerprint
  belongs_to :user_agent
  belongs_to :dhcp_vendor
  belongs_to :device
  belongs_to :mac_vendor

  belongs_to :submitter, :class_name => "User"

  before_validation :on => :create do
    set_empty
  end

  attr_accessor :processed_method

  #validates_uniqueness_of :dhcp_fingerprint_id, :scope => [ :user_agent_id, :dhcp_vendor_id ], :message => "A combination with these attributes already exists"
  validates_presence_of :dhcp_fingerprint_id, :dhcp_vendor_id, :user_agent_id
  validate :validate_combination_uniqueness

  scope :unknown, -> {where(:device => nil)}   
  scope :unrated, -> {where('device_id is not null and score=0')}   

  def self.simple_search_joins
    return {
      :has => [],
      :belongs_to => [
        :dhcp_fingerprint,
        :user_agent,
        :dhcp_vendor,
        :mac_vendor,
        :device,
        :submitter,
      ]
    }
  end

  def set_empty
    self.user_agent_id = 0 unless self.user_agent_id
    self.dhcp_fingerprint_id = 0 unless self.dhcp_fingerprint_id
    self.dhcp_vendor_id = 0 unless self.dhcp_vendor_id
  end

  def validate_combination_uniqueness
    existing = Combination.where(:dhcp_fingerprint_id => dhcp_fingerprint_id, :user_agent_id => user_agent_id, :dhcp_vendor_id => dhcp_vendor_id, :mac_vendor_id => mac_vendor_id).size
    if (persisted? && existing > 1) || (!persisted? && existing > 0)
      errors.add(:combination, 'A unique set of attributes must be set. This combination already exists')
    end
  end

  def validate_submition
    if device.nil?
      errors.add(:device, 'cannot be empty')
    end
    if version.nil? or version.empty?
      errors.add(:version, 'cannot be empty')
    end
  end

  def user_submit
    validate_submition
    if errors.empty? && save
      return true
    else
      return false
    end
  end

  def self.score_from_discoverers(discoverers)
    disc_per_device = {}
    score_per_device = {} 
    discoverers.each do |discoverer| 
      disc_per_device[discoverer.device] = [] if disc_per_device[discoverer.device].nil?
      disc_per_device[discoverer.device] << discoverer

    end
    disc_per_device.each do |device, discoverers|
      total = device.discoverers.size
      matched = discoverers.size
      
      score = 0
      discoverers.each{|discoverer| score += discoverer.priority}
      device.parents.each do |parent|
        if disc_per_device.has_key? parent
          disc_per_device[parent].each{|discoverer| score += discoverer.priority}
        end
      end
      logger.debug device.full_path
      logger.debug score
      score_per_device[device] = score
    end
    return score_per_device
  end

  def self.add_condition(condition, started)
    if started
      return "or #{condition} " 
    else
      return "#{condition} "
    end
  end

end

