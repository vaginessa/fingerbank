require 'fingerbank_cache/discoverer'

class Discoverer < FingerbankModel 
  has_many :device_rules, :class_name => 'Rule', :foreign_key => 'device_discoverer_id'
  has_many :version_rules, :class_name => 'Rule', :foreign_key => 'version_discoverer_id'
  belongs_to :device

  validates_presence_of :device_id
  validates_presence_of :description
  validates :priority, :numericality => {:only_integer => true}

  def self.simple_search_joins
    return {
      :has => [],
      :belongs_to => [:device]
    }
  end

  def version_finder
    if self.version.nil?
      return "''"
    elsif self.version.match(/^PREG_CAPTURE/) || self.version.match(/^REPLACE/) || self.version.match(/^PREG_REPLACE/)
      return self.version
    else
      return "'#{self.version}'"
    end
  end

  def self.device_matching_discoverers
    return FingerbankCache.get("device_matching_discoverers") || {}
  end

  def find_matches
    query = ""
    started = false

    self.device_rules.each do |rule|
      to_add = Combination.add_condition rule.computed, started
      
      query += to_add
      started = true
    end

    unless query.empty?
      sql = "SELECT combinations.id from combinations 
              inner join user_agents on user_agents.id=combinations.user_agent_id 
              inner join dhcp_fingerprints on dhcp_fingerprints.id=combinations.dhcp_fingerprint_id
              inner join dhcp_vendors on dhcp_vendors.id=combinations.dhcp_vendor_id
              left join mac_vendors on mac_vendors.id=combinations.mac_vendor_id
              WHERE (#{query});"
      records = ActiveRecord::Base.connection.execute(sql)
      return records
    else
      return [] 
    end
  end

  def self.discoverers_ifs
    ifs = FingerbankCache.get("ifs_for_discoverers") || ""
    conditions = FingerbankCache.get("ifs_association_for_discoverers") || []
    return ifs, conditions
  end

  def self.regex_assoc
    return FingerbankCache.get("regex_assoc") || nil
  end

end
