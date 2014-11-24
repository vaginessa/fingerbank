namespace :fbcache do
  task clear_discoverers: :environment do
    Rails.cache.delete("device_matching_discoverers")
    FingerbankCache.delete("ifs_for_discoverers")
    FingerbankCache.delete("ifs_conditions_for_discoverers")
  end

  task build_discoverers: :environment do 
    Combination.device_matching_discoverers
    Combination.first.find_matching_discoverers
  end

  task refresh_stats: :environment do
    puts ActionController::Base.new.expire_fragment 'stats'
    require 'net/http'
    http = Net::HTTP.new("fingerbank.inverse.ca", 443)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    resp = http.get("/stats")
    puts "Done" 
  end

end
