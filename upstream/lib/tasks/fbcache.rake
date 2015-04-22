require 'net/http'

namespace :fbcache do |ns|
  task :list do
    puts 'All tasks:'
    puts ns.tasks
  end

  task clear_discoverers: :environment do
    FingerbankCache.delete("device_matching_discoverers")
    FingerbankCache.delete("ifs_for_discoverers")
    FingerbankCache.delete("ifs_conditions_for_discoverers")
    puts "Cleared discoverers cache" 
  end

  task build_discoverers: :environment do 
    Discoverer.fbcache
    # make sure the web server has a cache 
    http = Net::HTTP.new("fingerbank.inverse.ca", 443)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    resp = http.get("/discoverers/cache")
    puts "Done rebuilding discoverers cache" 
  end

  task refresh_stats: :environment do
    puts ActionController::Base.new.expire_fragment 'stats'
    http = Net::HTTP.new("fingerbank.inverse.ca", 443)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    resp = http.get("/combinations")
    puts "Done refreshing stats"
  end

  task benchmark_processing: :environment do
    # do it once to bring the cache in mem
    
    combination = UserAgent.last.combinations.first
    combination.find_matching_discoverers_cache
    combination.find_matching_discoverers_local
    combination.find_matching_discoverers_tmp_table

    TIMES=30
    Benchmark.bm(13) do |x|
      x.report("pre-computed :") { (1..TIMES).each { |i| combination.find_matching_discoverers_cache } }
      x.report("local        :") { (1..TIMES).each { |i| combination.find_matching_discoverers_local} }
      x.report("tmp-table    :") { (1..TIMES).each { |i| combination.find_matching_discoverers_tmp_table} }
    end
  end

end
