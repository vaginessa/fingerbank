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

    UserAgent.create(:value => "Mozilla/5.0 (Linux; Android 4.4.2; 0PCV1 Build/KOT49H) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.89 Mobile Safari/537.36")    
    user_agent = UserAgent.where(:value => "Mozilla/5.0 (Linux; Android 4.4.2; 0PCV1 Build/KOT49H) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.89 Mobile Safari/537.36").first
    Combination.create(:user_agent => user_agent, :dhcp_fingerprint_id => 0, :dhcp_vendor_id => 0)
    combination = Combination.where(:user_agent => user_agent, :dhcp_fingerprint_id => 0, :dhcp_vendor_id => 0).first
    
    # do it once to bring the cache in mem
    Discoverer.fbcache
    combination.find_matching_discoverers_cache
    combination.find_matching_discoverers_local
    combination.find_matching_discoverers_tmp_table

    TIMES=1
    Benchmark.bm(13) do |x|
      x.report("pre-computed :") { (1..TIMES).each { |i| combination.find_matching_discoverers_cache } }
      x.report("local        :") { (1..TIMES).each { |i| combination.find_matching_discoverers_local} }
      x.report("tmp-table    :") { (1..TIMES).each { |i| combination.find_matching_discoverers_tmp_table} }
    end

    combination.update(:device => nil, :score => nil, :version => nil)

    # processing with all cache
    Benchmark.bm(20) do |x|
      x.report("processing fast cache :") { (1..TIMES).each { |i| combination.process} }
    end

    # without device_matching_discoverers
    FingerbankCache.delete("device_matching_discoverers")
    Benchmark.bm(20) do |x|
      x.report("processing slow cache :") { (1..TIMES).each { |i| combination.process} }
    end

  end

end
