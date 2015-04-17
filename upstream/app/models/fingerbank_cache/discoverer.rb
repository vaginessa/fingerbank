
class Discoverer < FingerbankModel
  def self.fbcache
    Discoverer.build_device_matching_discoverers
    Discoverer.build_discoverers_ifs
  end

  def self.build_device_matching_discoverers
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

  def self.build_discoverers_ifs
    ifs_started = false

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

    return ifs, conditions
  end

  private
  def self.if_for_query(query, started)
    if started
      return "IF(#{query}, 1, 0), "
    else
      return "IF(#{query}, 1, 0) "
    end
  end
end
