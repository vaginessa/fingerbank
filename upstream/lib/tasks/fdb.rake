require 'iconv'

namespace :fdb do |ns|
  task :list do
    puts 'all tasks:'
    puts ns.tasks
  end

  task reset_timeframed_requests: :environment do
    User.update_all(:timeframed_requests => 0)
  end

  task :sort_combination, [:combination_id] => [:environment] do |t, args|
    if args[:combination_id].nil?
      combinations = Combination.all
    else
      combinations = [Combination.find(args[:combination_id])]
    end

    combinations.each do |combination| 
      combination.process(:with_version => true, :save => true)
    end
  end

  task :sort_combination_no_version, [:combination_id] => [:environment] do |t, args|
    if args[:combination_id].nil?
      combinations = Combination.all
    else
      combinations = [Combination.find(args[:combination_id])]
    end

    combinations.each do |combination| 
      combination.process(:with_version => false, :save => true)
    end
  end

  task :reevaluate_for_discoverer, [:discoverer_id] => [:environment] do |t, args|
    if args[:discoverer_id].nil?
      puts "Missing discoverer id"
      next
    end

    discoverer = Discoverer.find args[:discoverer_id]

    Combination.all.each do |combination|
      if combination.matches_discoverer?(discoverer)
        puts "Combination #{combination.id} matches. Reprocessing"
        combination.process(:with_version => true, :save => true)
      end
    end
    
  end

  task package: :environment do

    config   = Rails.configuration.database_configuration
    host     = config[Rails.env]["host"]
    database = config[Rails.env]["database"]
    username = config[Rails.env]["username"]
    password = config[Rails.env]["password"]

    sqlite_sql = `sh #{Rails.root.join('db', 'mysql2sqlite.sh')} #{host} #{username} #{password} #{database} "combinations dhcp_vendors user_agents dhcp_fingerprints mac_vendors devices"` 
    dump_fname = Rails.root.join('tmp', "#{Time.now.to_i}.sqlite3dump.sql")
    bak_dump_fname = Rails.root.join('tmp', "#{Time.now.to_i}.sqlite3dump.sql.bak")
    sqlite_sql_output = File.open(dump_fname, 'w') 
    sqlite_sql_output << sqlite_sql
    sqlite_sql_output.close

    # rename the tables to put them singular
    success = system ('sed -i.bak s/\"devices\"/\"device\"/g '+dump_fname.to_s)
    success = system ('sed -i.bak s/\"combinations\"/\"combination\"/g '+dump_fname.to_s)
    success = system ('sed -i.bak s/\"dhcp_fingerprints\"/\"dhcp_fingerprint\"/g '+dump_fname.to_s)
    success = system ('sed -i.bak s/\"user_agents\"/\"user_agent\"/g '+dump_fname.to_s)
    success = system ('sed -i.bak s/\"mac_vendors\"/\"mac_vendor\"/g '+dump_fname.to_s)
    success = system ('sed -i.bak s/\"dhcp_vendors\"/\"dhcp_vendor\"/g '+dump_fname.to_s)

    # replace quote escaping for sqlite3
    success = system ("sed -i.bak \"s/\\\\\\\\'/''/g\" "+dump_fname.to_s)

    db_fname = Rails.root.join('db', 'package', "#{Time.now.to_i}.sqlite3")
    success = system ("sqlite3 #{db_fname} < #{dump_fname}")

    Rake::Task["fdb:add_devices_mac_vendors"].invoke(db_fname.to_s)

    #File.delete dump_fname
    # the sed stuff creates a backup file. we flush it too
    #File.delete bak_dump_fname

    FileUtils.cp db_fname, Rails.root.join('db', 'package', "packaged.sqlite3")

  end

  task create_base_admin: :environment do
    User.create!(:github_uid => "3857942", :name => 'TBD', :level => 1)
  end

  task remove_dup_dhcp_vendors: :environment do
    assocs = {}
    Combination.all.each do |combination|
      dhcp_vendor_value = combination.dhcp_vendor.value
      if assocs.has_key? dhcp_vendor_value
        assocs[dhcp_vendor_value] << combination
      else
        assocs[dhcp_vendor_value] = [combination]
      end
    end

    DhcpVendor.delete_all

    assocs.each do |dhcp_vendor_value, combinations|
      dhcp_vendor = DhcpVendor.create!(:value => dhcp_vendor_value)
      puts dhcp_vendor
      combinations.each do |combination|
        combination.dhcp_vendor = dhcp_vendor
        combination.save!
      end
    end
  

  end

  task :add_devices_mac_vendors, [:db_path] => [:environment] do |t, args|
    if args[:db_path].nil?
      next
    end

    packaged = SQLite3::Database.open args[:db_path]
    packaged.execute("create table devices_mac_vendors(device_id int(11), mac_vendor varchar(6))")
    Combination.all.each do | combination | 
      device_id = combination.device.id if combination.device
      mac_vendor = combination.mac_vendor.mac if combination.mac_vendor
      if device_id && mac_vendor
        packaged.execute("insert into devices_mac_vendors(device_id, mac_vendor) VALUES(?, ?)", device_id, mac_vendor)   
      end
    end
  end

end
