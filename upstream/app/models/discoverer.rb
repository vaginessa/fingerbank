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

  def self.cache
    Discoverer.device_matching_discoverers
    Discoverer.discoverers_ifs
  end

  def self.device_matching_discoverers
    # we use the unserialized cache (pretty much a global variable)
    if FingerbankCache.get("device_matching_discoverers") 
      return FingerbankCache.get("device_matching_discoverers")
    end

    # cache miss, we compute the data

    combinations = {}
    Combination.all.each do |c|
      combinations[c.id] = []
    end
    Discoverer.all.each do |discoverer|
      records = discoverer.find_matches
      records.each do |record|
        begin
          combinations[record[0]] << discoverer
        rescue
          combinations[record[0]] = []
          combinations[record[0]] << discoverer
        end
      end
      logger.info "Found #{records.size} hits for discoverer #{discoverer.id}"
    end    
    # We keep our result in the cache
    success = FingerbankCache.set("device_matching_discoverers", combinations)
    logger.info "Writing cache gave #{success}"
    return combinations
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

  def self.if_for_query(query, started)
    if started
      return "IF(#{query}, 1, 0), "
    else
      return "IF(#{query}, 1, 0) "
    end
  end

  def self.discoverers_ifs
    ifs_started = false
    ifs = FingerbankCache.get("ifs_for_discoverers") || ""
    conditions = FingerbankCache.get("ifs_association_for_discoverers") || []

    if ifs.empty? || conditions.empty?
      ifs = ""
      conditions = []
      Discoverer.all.each do |discoverer|

        query = ""
        started = false

        discoverer.device_rules.each do |rule|
          to_add = rule.computed.gsub('dhcp_fingerprints.value', 'dhcp_fingerprint')
          to_add = to_add.gsub('user_agents.value', 'user_agent')
          to_add = to_add.gsub('dhcp_vendors.value', 'dhcp_vendor')
          to_add = Combination.add_condition to_add, started
          
          query += to_add
          started = true
        end
    
        unless query.empty?
          ifs.prepend(Discoverer.if_for_query(query, ifs_started))
          conditions.unshift discoverer
          ifs_started = true
        end
      end    
      success = FingerbankCache.set("ifs_for_discoverers", ifs)
      logger.info "Writing ifs_for_discoverers gave #{success}"
      success = FingerbankCache.set("ifs_association_for_discoverers", conditions)
      logger.info "Writing ifs_association_for_discoverers gave #{success}"

    end

    return ifs, conditions

  end



end
