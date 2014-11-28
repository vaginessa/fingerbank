require 'iconv'

namespace :import do

  task :android_models, [:file_path] => [:environment] do |t, args|
    ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
    if args[:file_path].nil?
      puts "No file specified. Exiting"
      next
    end
  
    line_num=0
    text=File.open('tmp/android_models.txt').read
    text.gsub!(/\r\n?/, "\n")
    state = "looking_for_manufacturer"
    manufacturer = ""
    generic_android = Device.where(:name => "Generic Android").first
    count = 0
    text.each_line do |line|
      line.gsub!(/\n/, "")
      line.gsub!(/^ */, "")
      #puts "LINE = #{line}"
      #puts "MANUFACTURER = #{manufacturer}"
      #puts "STATE = #{state}"
      #$stdin.read
      if state == "looking_for_manufacturer" and !line.empty?
        state = "looking_for_device"
        #manufacturer = line
        manufacturer = Device.where('lower(name) = ?',  "#{line} Android".downcase).first
        if manufacturer.nil?
          puts "Manufacturer #{line} Android doesn't exists"
          manufacturer = Device.create!(:name => "#{line} Android", :parent => generic_android, :inherit => true)
          puts "Created manufacturer #{manufacturer.name}"
        else
          puts "Manufacturer #{manufacturer.name} exists"
        end
      elsif state == "looking_for_device" or state=="parsing_devices" and !line.empty?
        state = "parsing_devices"
        count += 1
        puts "#{line}"
        data = line.split('(')
        name = data[0]
        name = ic.iconv(name + ' ')[0..-2]
        name.gsub!(/ *$/, "")
        puts "'#{name}'"

        device = Device.where('lower(name) = ?', name.downcase).first
        if device.nil?
          puts "Device #{name} doesn't exist yet. Creating it"
          device = Device.create!(:name => name, :parent => manufacturer, :inherit => true)
        else
          puts "Device #{name} exists"
        end

        unless data[1].nil?
          model_info = data[1].split('/')
          unless model_info[1].nil?
            model_number = model_info[1].sub(/\)/, '') 
            model_number = model_number.sub('\'', '\'\'') 
            model_number = ic.iconv(model_number + ' ')[0..-2]
            discoverer = Discoverer.where(:device => device).where("lower(description) = ?", "#{name} from model # on User Agent".downcase).first
            rule_value = "user_agents.value regexp '#{model_number}[\); ]{1}' and user_agents.value not regexp '[:word:]#{model_number}'"
            unless discoverer.nil?
              rule_already_in = false
              discoverer.device_rules.each do |rule|
                if rule.value == rule_value
                  rule_already_in = true
                  break
                end
              end
    
              unless rule_already_in
                puts "Adding rule for model # #{model_number} to device #{device.name}"
                rule = Rule.create!(:value => rule_value, :device_discoverer => discoverer)
              end
            else
              discoverer = Discoverer.create!(:description => "#{name} from model # on User Agent", :priority => 5, :device => device)
              puts "Adding rule for model # #{model_number} to device #{device.name}"
              rule = Rule.create!(:value => rule_value, :device_discoverer => discoverer)
            end

          end
        end

      elsif state == "parsing_devices" and line.empty?
        state = "looking_for_manufacturer"
      end
    end

    puts count
   
  end

  task :discover_windows_phone => :environment do
    windows_phone = Device.where(:name => "Windows Phone").first
    UserAgent.all.each do |user_agent|
      value = user_agent.value.nil? ? '' : user_agent.value
      matchdata = value.match(/.*Windows Phone.*;[ ]{0,1}([A-Za-z0-9 ]+);[ ]{0,1}([A-Za-z0-9 ]+)[);]{1}.*/)
      unless matchdata.nil?
        model = matchdata[2]
        manufacturer_name = matchdata[1]
        puts "#{manufacturer_name} #{model}"
        puts user_agent.value

        manufacturer = Device.where('lower(name) = ?',  "#{manufacturer_name} Windows Phone".downcase).first
        if manufacturer.nil?
          puts "Manufacturer #{manufacturer_name} Windows Phone doesn't exists"
          manufacturer = Device.create!(:name => "#{manufacturer_name} Windows Phone", :parent => windows_phone, :inherit => true)
          puts "Created manufacturer #{manufacturer.name}"
        end

        puts "Discoverered #{model}"
        device = Device.where("lower(name) = ?", model.downcase).first
        if device.nil?
          device = Device.create!(:name => model, :parent => manufacturer, :inherit => true)
          puts "Created device #{model}"
        else
          puts "Device #{model} exists"
        end

        rule_value = "user_agents.value regexp '.*Windows Phone.*;[ ]{0,1}#{manufacturer_name};[ ]{0,1}#{model}[);].*'"

        discoverer = Discoverer.where(:device => device).where("lower(description) = ?", "#{model} from model # on User Agent".downcase).first
        unless discoverer.nil?
          rule_already_in = false
          discoverer.device_rules.each do |rule|
            if rule.value == rule_value 
              rule_already_in = true
              break
            end
          end

          unless rule_already_in
            puts "Adding rule for model # #{model} to device #{device.name}"
            rule = Rule.create!(:value => rule_value, :device_discoverer => discoverer)
          end
        else
          discoverer = Discoverer.create!(:description => "#{model} from model # on User Agent", :priority => 5, :device => device)
          puts "Adding rule for model # #{model} to device #{device.name}"
          rule = Rule.create!(:value => rule_value, :device_discoverer => discoverer)
        end


      end




    end
  end


  task :discover_blackberry_models => :environment do
    blackberry = Device.where(:name => "RIM BlackBerry").first
    UserAgent.all.each do |user_agent|
      value = user_agent.value.nil? ? '' : user_agent.value
      matchdata = value.match(/ (BlackBerry[; ][0-9]+)/)
      model = matchdata.nil? ? nil : matchdata[0]
      if model
        model = model.gsub(/^ /, '')
        model_untouched = model
        model = model.gsub(';', ' ')
        puts "Discoverered #{model}"
        device = Device.where("lower(name) = ?", model.downcase).first
        if device.nil?
          device = Device.create!(:name => model, :parent => blackberry, :inherit => true)
          puts "Created device #{model}"
        else
          puts "Device #{model} exists"
        end

        discoverer = Discoverer.where(:device => device).where("lower(description) = ?", "#{model} from model # on User Agent".downcase).first
        unless discoverer.nil?
          rule_already_in = false
          discoverer.device_rules.each do |rule|
            if rule.value == "user_agents.value LIKE '%#{model_untouched}%'"
              rule_already_in = true
              break
            end
          end

          unless rule_already_in
            puts "Adding rule for model # #{model_untouched} to device #{device.name}"
            rule = Rule.create!(:value => "user_agents.value LIKE '%#{model_untouched}%'", :device_discoverer => discoverer)
          end
        else
          discoverer = Discoverer.create!(:description => "#{model} from model # on User Agent", :priority => 5, :device => device)
          puts "Adding rule for model # #{model_untouched} to device #{device.name}"
          rule = Rule.create!(:value => "user_agents.value LIKE '%#{model_untouched}%'", :device_discoverer => discoverer)
        end
      end
    end
  end


  task :merge_stats, [:db_path, :days_to_merge] => [:environment] do |t, args|

    # what is the last inserted that has no owner (should be by this script)
    last_inserted = Combination.where(:submitter_id => nil).order(created_at: :desc).first
    # the stats database uses the local time at Inverse inc.
    last_inserted_time = Time.now.in_time_zone("Eastern Time (US & Canada)") 
    puts last_inserted_time

    if args[:db_path].nil?
      puts "No database specified. Exiting"
      next
    end

    if args[:days_to_merge].nil?
      days_to_merge = '365'
      puts "No delay set. Using #{days_to_merge} days"
    else
      days_to_merge = args[:days_to_merge]
    end

    orig = SQLite3::Database.open args[:db_path]

    stm = orig.prepare "select count(*) as total_count from stats_dhcp left outer join stats_http on stats_dhcp.mac=stats_http.mac where stats_dhcp.timestamp > date('now', '-#{days_to_merge} days')"

    result = stm.execute

    total_count = 0
    result.each do |row| total_count = row[0] end

    stm = orig.prepare "select stats_dhcp.mac, stats_dhcp.dhcp_fingerprint, stats_dhcp.vendor_id, stats_http.user_agent from stats_dhcp left outer join stats_http on stats_dhcp.mac=stats_http.mac where stats_dhcp.timestamp > date('now', '-#{days_to_merge} days') "

    result = stm.execute

    count = 0
    result.each do |row|
      ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')

      puts "Processing #{row[0]} #{count}/#{total_count}"

      mac_value = ic.iconv(row[0] + ' ')[0..-2][0..7]
      dhcp_fingerprint_value = row[1].nil? ? '' : ic.iconv(row[1] + ' ')[0..-2]
      dhcp_vendor_value = row[2].nil? ? '' : ic.iconv(row[2] + ' ')[0..-2]
      user_agent_value = row[3].nil? ? '' : ic.iconv(row[3] + ' ')[0..-2]
      DhcpFingerprint.create(:value => dhcp_fingerprint_value)
      dhcp_fingerprint = DhcpFingerprint.where(:value => dhcp_fingerprint_value).first
      UserAgent.create(:value => user_agent_value)
      user_agent = UserAgent.where(:value => user_agent_value).first
      DhcpVendor.create(:value => dhcp_vendor_value)
      dhcp_vendor = DhcpVendor.where(:value => dhcp_vendor_value).first 

      combination = Combination.new
      combination.dhcp_fingerprint = dhcp_fingerprint
      combination.user_agent = user_agent
      combination.dhcp_vendor = dhcp_vendor
      combination.mac_vendor = MacVendor.from_mac(mac_value)
      combination.save
      combination = Combination.where(:user_agent => user_agent, :dhcp_fingerprint => dhcp_fingerprint, :dhcp_vendor => dhcp_vendor, :mac_vendor => combination.mac_vendor).first

      count+=1

    end

    stm = orig.prepare "select count(*) as total_count from stats_http left outer join stats_dhcp on stats_dhcp.mac=stats_http.mac where stats_dhcp.timestamp > date('now', '-#{days_to_merge} days')"

    result = stm.execute

    total_count = 0
    result.each do |row| total_count = row[0] end

    stm = orig.prepare "select stats_dhcp.mac, stats_dhcp.dhcp_fingerprint, stats_dhcp.vendor_id, stats_http.user_agent from stats_http left outer join stats_dhcp on stats_dhcp.mac=stats_http.mac where stats_dhcp.timestamp > date('now', '-#{days_to_merge} days') "

    result = stm.execute

    count = 0
    result.each do |row|
      ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')

      puts "Processing #{row[0]} #{count}/#{total_count}"

      mac_value = row[0].nil? ? '' : ic.iconv(row[0] + ' ')[0..-2][0..7]
      dhcp_fingerprint_value = row[1].nil? ? '' : ic.iconv(row[1] + ' ')[0..-2]
      dhcp_vendor_value = row[2].nil? ? '' : ic.iconv(row[2] + ' ')[0..-2]
      user_agent_value = row[3].nil? ? '' : ic.iconv(row[3] + ' ')[0..-2]
      DhcpFingerprint.create(:value => dhcp_fingerprint_value)
      dhcp_fingerprint = DhcpFingerprint.where(:value => dhcp_fingerprint_value).first
      UserAgent.create(:value => user_agent_value)
      user_agent = UserAgent.where(:value => user_agent_value).first
      DhcpVendor.create(:value => dhcp_vendor_value)
      dhcp_vendor = DhcpVendor.where(:value => dhcp_vendor_value).first 

      combination = Combination.new
      combination.dhcp_fingerprint = dhcp_fingerprint
      combination.user_agent = user_agent
      combination.dhcp_vendor = dhcp_vendor
      combination.mac_vendor = MacVendor.from_mac(mac_value)
      combination.save
      combination = Combination.where(:user_agent => user_agent, :dhcp_fingerprint => dhcp_fingerprint, :dhcp_vendor => dhcp_vendor, :mac_vendor => combination.mac_vendor).first

      count+=1

    end

  end


  task :rewrite_android_rules => :environment do 
    Rule.all.each do |rule|
      model = rule.value.match /user_agents.value regexp ' (.*)\[\)\; \]\{1\}'/i
      if model
        puts model
        puts model[1] 
        new_value = "user_agents.value regexp '#{model[1]}[\); ]{1}' and user_agents.value not regexp '[:word:]#{model[1]}'"
        rule.value = new_value 
        rule.save!
      end
    end
  end

  task :cfnetwork, [:file_path] => [:environment] do |t, args|
    if args[:file_path].nil?
      puts "No file path specified. Exiting"
      next
    end
    require 'nokogiri'
    page = Nokogiri::HTML(open(args[:file_path]))
    table = page.css('table')
    table.css('tr').each do |line|
      cf_network = nil
      model = nil
      version = nil
      got_cf_network = false
      line.css('td').each do |info|
        unless got_cf_network
          cf_network = info.text
          got_cf_network = true
        else
          data = info.text.match(/([a-zA-Z ]+) ([0-9.]+)/)
          if data
            model = data[1]
            version = data[2]
          end
          break
        end
      end
      if cf_network && model
        puts cf_network
        puts model
        puts version 

        if model == "Mac OSX"
          device = Device.where(:name => "Mac OS X").first
        elsif model == "iOS"
          device = Device.where(:name => "Apple iPod, iPhone or iPad").first
        else
          next
        end

        description = "#{device.name} from #{cf_network} on user agent"

        discoverer = Discoverer.where(:device => device).where("lower(description) = ?", description.downcase).first
        if discoverer.nil?
          rule_value = "user_agents.value like '%#{cf_network}%'"
          discoverer = Discoverer.create!(:description => description, :priority => 5, :device => device)
          puts "Adding rule for cf network #{cf_network} to device #{device.name} (#{rule_value})"
          rule = Rule.create!(:value => rule_value, :device_discoverer => discoverer)
        end

        description = "#{device.name} version #{version} from #{cf_network} on user agent"
        discoverer = Discoverer.where(:device => device).where("lower(description) = ?", description.downcase).first
         if discoverer.nil? && version
          rule_value = "user_agents.value like '%#{cf_network}%'"
          discoverer = Discoverer.create!(:description => description, :priority => 5, :device => device, :version => version)
          puts "Adding rule for cf network #{cf_network} to device #{device.name} (#{rule_value}) with version #{version}"
          rule = Rule.create!(:value => rule_value, :version_discoverer => discoverer)
        end       

      end
    end
  end

end
