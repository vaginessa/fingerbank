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

  def process(options = {:with_version => false, :save => true})
    discoverer_detected_device = nil
    new_score = nil
    discoverers_match = Discoverer.device_matching_discoverers[id]
    if discoverers_match.nil?
      logger.info "Cache miss in device_matching_discoverers for combination #{id}"
      discoverers_match = find_matching_discoverers
    else
      self.processed_method = "device_matching_discoverers"
    end

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
      else
        save!
        find_version
        logger.debug self.device.nil? ? "Unknown device" : "Detected device "+self.device.full_path  
        logger.debug "Score "+score.to_s
        logger.debug version ? "Version "+version : "Unknown version"
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
      self.processed_method = "find_matching_discoverers"
    else
      logger.warn "Computing discoverers data without cache. THIS WILL BE LONG !!!!"
      self.processed_method = "find_matching_discoverers_long"
      matches = find_matching_discoverers_long
    end

    return matches 
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

