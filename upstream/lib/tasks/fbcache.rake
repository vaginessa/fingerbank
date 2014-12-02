require 'net/http'

namespace :fbcache do
  task clear_discoverers: :environment do
    Rails.cache.delete("device_matching_discoverers")
    FingerbankCache.delete("ifs_for_discoverers")
    FingerbankCache.delete("ifs_conditions_for_discoverers")
  end

  task build_discoverers: :environment do 
    Discoverer.cache
    # make sure the web server has a cache 
    http = Net::HTTP.new("fingerbank.inverse.ca", 443)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    resp = http.get("/discoverers/cache")
    puts "Done" 
  end

  task refresh_stats: :environment do
    puts ActionController::Base.new.expire_fragment 'stats'
    http = Net::HTTP.new("fingerbank.inverse.ca", 443)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    resp = http.get("/combinations")
    puts "Done" 
  end

end
