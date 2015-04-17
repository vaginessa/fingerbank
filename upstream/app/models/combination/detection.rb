

class Combination < FingerbankModel
  def process(options = {:with_version => false, :save => true})
    discoverer_detected_device = nil
    new_score = nil

    discoverers_match = find_matching_discoverers

    unless discoverers_match.empty?
      deepest = 0
      discoverers = discoverers_match 
      scores = Combination.score_from_discoverers discoverers
      discoverer_detected_device, new_score = (scores.sort_by {|key, value| value}).last
      self.device = discoverer_detected_device 
      self.score = new_score unless new_score.nil?
    else
      logger.warn "empty device rules for #{id}"
    end 

    if options[:with_version]
      if discoverer_detected_device.nil?
        # no choice really
        # leave as is 
        logger.warn "Couldn't find device for combination #{id} so can't find version"
      else
        save!
        find_version
        logger.debug self.device.nil? ? "Unknown device" : "Detected device "+self.device.full_path  
        logger.debug "Score "+score.to_s
        logger.info version ? "Version "+version : "Unknown version"
      end
    end
    save! if options[:save]
  end


  def matches_discoverer?(discoverer)
    matches = []
    discoverer.device_rules.each do |rule|
      computed = rule.computed
      sql = "SELECT combinations.id from combinations 
              inner join user_agents on user_agents.id=combinations.user_agent_id 
              inner join dhcp_fingerprints on dhcp_fingerprints.id=combinations.dhcp_fingerprint_id
              inner join dhcp_vendors on dhcp_vendors.id=combinations.dhcp_vendor_id
              left join mac_vendors on mac_vendors.id=combinations.mac_vendor_id
              WHERE (combinations.id=#{id}) AND #{computed};"
      records = ActiveRecord::Base.connection.execute(sql)
      unless records.size == 0
        matches.push rule
        logger.debug "Matched OS rule in #{discoverer.id}"
      end
    end

    discoverer.version_rules.each do |rule|
      computed = rule.computed
      sql = "SELECT combinations.id from combinations 
              inner join user_agents on user_agents.id=combinations.user_agent_id 
              inner join dhcp_fingerprints on dhcp_fingerprints.id=combinations.dhcp_fingerprint_id
              inner join dhcp_vendors on dhcp_vendors.id=combinations.dhcp_vendor_id
              left join mac_vendors on mac_vendors.id=combinations.mac_vendor_id
              WHERE (combinations.id=#{id}) AND #{computed};"
      records = ActiveRecord::Base.connection.execute(sql)
      unless records.size == 0
        matches.push rule
        logger.debug "Matched OS rule in #{discoverer.id}"
      end
    end

    return !matches.empty?

  end

  def find_matching_discoverers
    discoverers_match = find_matching_discoverers_cache
    unless discoverers_match.nil?
      logger.debug "Cache hit in device_matching_discoverers for combination #{id}"
      self.processed_method = "find_matching_discoverers_cache"
      return discoverers_match
    end

    discoverers_match = find_matching_discoverers_tmp_table
    unless discoverers_match.nil?
      logger.debug "Cache hit in ifs_for_discoverer for combination #{id}"
      self.processed_method = "find_matching_discoverers_tmp_table"
      return discoverers_match
    end

    discoverers_match = find_matching_discoverers_long
    logger.warn "Computing discoverers data without cache. THIS WILL BE LONG !!!!"
    self.processed_method = "find_matching_discoverers_long"
    # Notify full cache miss to discoverer
    Discoverer.full_cache_miss

    return discoverers_match
  end

  def find_matching_discoverers_cache
    return Discoverer.device_matching_discoverers[id]
  end

  def find_matching_discoverers_tmp_table
    valid_discoverers = []
    ifs, conditions = Discoverer.discoverers_ifs
    matches = []

    unless ifs.empty?
      beginning_time = Time.now
      temp_combination = TempCombination.create!(:dhcp_fingerprint => dhcp_fingerprint.value, :user_agent => user_agent.value, :dhcp_vendor => dhcp_vendor.value)
      end_time = Time.now
      logger.info "Time elapsed for temp creation #{(end_time - beginning_time)*1000} milliseconds"  
   

      logger.debug "Computing discoverer from the temp table with the ifs from the cache"
      sql = "SELECT #{ifs} from temp_combinations 
              WHERE (id=#{temp_combination.id});"

      beginning_time = Time.now
      records = ActiveRecord::Base.connection.execute(sql)
      end_time = Time.now
      logger.info "Time elapsed for big SQL query #{(end_time - beginning_time)*1000} milliseconds"  

      count = 0 
      records.each do |record|
        while !record[count].nil?
          if record[count] == 1
            discoverer = conditions[count]
            matches.push discoverer
            logger.debug "Matched OS rule in #{discoverer.id}"
          end
          count+=1
        end
      end
      temp_combination.delete
      self.processed_method = "find_matching_discoverers_tmp_table"

      return matches 
    else
      return nil
    end

  end

  def find_matching_discoverers_long
    discoverers = Discoverer.all
    discoverers_matched = []
    discoverers.each do |discoverer|
      matches = []
      version_discovered = ''
      discoverer.device_rules.each do |rule|
        computed = rule.computed
        sql = "SELECT #{discoverer.id} from combinations 
                inner join user_agents on user_agents.id=combinations.user_agent_id 
                inner join dhcp_fingerprints on dhcp_fingerprints.id=combinations.dhcp_fingerprint_id
                inner join dhcp_vendors on dhcp_vendors.id=combinations.dhcp_vendor_id
                left join mac_vendors on mac_vendors.id=combinations.mac_vendor_id
                WHERE (combinations.id=#{id}) AND #{computed};"
        records = ActiveRecord::Base.connection.execute(sql)
        unless records.size == 0
          matches.push rule
          logger.debug "Matched discocerer rule in #{discoverer.id}"
        end
      end
      unless matches.empty?
        discoverers_matched.push discoverer
      end
    end
    return discoverers_matched
  end

  def find_version
    if self.device.nil?
      logger.warn "device is nil"
      return
    end
    discoverers = device.tree_discoverers
    valid_discoverers = []
    versions_discovered = {} 
    discoverers.each do |discoverer|
      matches = []
      version_discovered = ''
      discoverer.version_rules.each do |rule|
        computed = rule.computed
        sql = "SELECT #{discoverer.version_finder} from combinations 
                inner join user_agents on user_agents.id=combinations.user_agent_id 
                inner join dhcp_fingerprints on dhcp_fingerprints.id=combinations.dhcp_fingerprint_id
                inner join dhcp_vendors on dhcp_vendors.id=combinations.dhcp_vendor_id
                left join mac_vendors on mac_vendors.id=combinations.mac_vendor_id
                WHERE (combinations.id=#{id}) AND #{computed};"
        records = ActiveRecord::Base.connection.execute(sql)
        unless records.size == 0
          matches.push rule
          logger.debug "Matched version rule in #{discoverer.id}"
          version_discovered = records.first[0]
        end
      end
      unless matches.empty?
        valid_discoverers.push discoverer
        versions_discovered[discoverer.id] = version_discovered 
      end
    end
    version_discoverer = valid_discoverers.sort{|a,b| a.priority <=> b.priority}.last
    self.version = versions_discovered[version_discoverer.id] unless version_discoverer.nil?
  end



end
