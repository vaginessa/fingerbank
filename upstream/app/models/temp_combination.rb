class TempCombination < ActiveRecord::Base

  def matches?(discoverer)
    matches = []
    version_discovered = ''
    discoverer.device_rules.each do |rule|

      computed = Discoverer.rule_for_tmp_table rule
      sql = "SELECT #{discoverer.id} from temp_combinations 
              WHERE (id=#{id}) AND #{computed};"
      records = ActiveRecord::Base.connection.execute(sql)
      unless records.size == 0
        matches.push rule
        logger.debug "Matched discocerer rule in #{discoverer.id}"
      end
    end
    unless matches.empty?
      return true
    else
      return false
    end
  end

  def matches_on_ifs?(ifs, conditions)
    matches = []
    logger.debug "Computing discoverer from the temp table with the ifs from the cache"
    sql = "SELECT #{ifs} from temp_combinations 
            WHERE (id=#{id});"

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

    return matches 
  end

end
