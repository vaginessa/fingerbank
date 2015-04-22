
class Discoverer < FingerbankModel
  def self.fbcache
    Discoverer.build_model_regex_assoc
    Discoverer.build_discoverers_ifs
    Discoverer.build_version_discoverers_ifs
    Discoverer.build_device_matching_discoverers
  end

  def self.full_cache_miss
    Thread.new do
     now = Time.now
      happened_at = Rails.cache.fetch("discoverers-full-cache-miss", :expires_in => 30.minute) {Time.now}
      if happened_at > now 
        AdminMailer.discoverers_cache_miss.deliver
        Discoverer.fbcache 
      end
      ActiveRecord::Base.connection.close
    end
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
    ifs, conditions = Discoverer.build_ifs(Discoverer.all)
    success = FingerbankCache.set("ifs_for_discoverers", ifs)
    logger.info "Writing ifs_for_discoverers gave #{success}"
    success = FingerbankCache.set("ifs_association_for_discoverers", conditions)
    logger.info "Writing ifs_association_for_discoverers gave #{success}"

    return ifs, conditions
  end

  def self.build_version_discoverers_ifs
    ifs, conditions = Discoverer.build_ifs(Discoverer.all, :device => false)
    version_discoverers_ifs = {:ifs => ifs, :conditions => conditions}
    success = FingerbankCache.set("version_discoverers_ifs", version_discoverers_ifs)
    logger.info "Writing version_discoverers_ifs gave #{success}"

    return version_discoverers_ifs
  end

  def self.build_ifs(discoverers, options={})
    options[:device] = options[:device].nil? || (options[:device]) ? true : false
    ifs_started = false

    ifs = ""
    conditions = []
    discoverers.each do |discoverer|

      query = ""
      started = false

      rules = options[:device] ? discoverer.device_rules : discoverer.version_rules

      rules.each do |rule|
        to_add = Discoverer.rule_for_tmp_table(rule)
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

    if ifs.empty?
      ifs = 0
    end

    return ifs, conditions
  end

  def self.build_model_regex_assoc
    assoc = {}
    non_regex_discoverers = []
    Discoverer.all.each do |discoverer|
      hit = false
      discoverer.device_rules.each do |rule|
        data = rule.computed.match(/user_agents.value[ ]+regexp '(.*?)'/)
        if data
          hit = true
          regexp = data[1]
          assoc[regexp] = discoverer
        end
      end
      non_regex_discoverers << discoverer unless(hit and discoverer.description =~ /from model #/)
    end
    success = FingerbankCache.set("model_regex_assoc", {:regex_assoc => assoc, :non_regex_discoverers => non_regex_discoverers, :non_regex_discoverers_ifs => Discoverer.build_ifs(non_regex_discoverers)})
    logger.info "Writing model_regex_assoc gave #{success}"
    return assoc 
  end

  def self.rule_for_tmp_table(rule)
    to_add = rule.computed.gsub('dhcp_fingerprints.value', 'dhcp_fingerprint')
    to_add = to_add.gsub('user_agents.value', 'user_agent')
    to_add = to_add.gsub('dhcp_vendors.value', 'dhcp_vendor')
    return to_add
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
