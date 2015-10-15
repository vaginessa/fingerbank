require 'iconv'

namespace :fdb do |ns|
  task :list do
    puts 'all tasks:'
    puts ns.tasks
  end

  task :test_discoverer, [:discoverer_id] => [:environment] do |t, args|
    puts "That discoverer device rules match : #{Discoverer.find(args[:discoverer_id]).find_device_matches.count} combinations"
    puts "That discoverer version rules match : #{Discoverer.find(args[:discoverer_id]).find_version_matches.count} combinations"
  end

  task reset_timeframed_requests: :environment do
    User.update_all(:timeframed_requests => 0)
    Rails.cache.delete_matched(/^user-with-key-.*/)
    User.all.each do |user|
      Rails.cache.delete("mail-#{user.name}-hourly-limit-reached")
    end
  end

  task :process_combination, [:combination_id] => [:environment] do |t, args|
    if args[:combination_id].nil?
      combinations = Combination.all
    else
      combinations = [Combination.find(args[:combination_id])]
    end

    combinations.each do |combination| 
      combination.process(:with_version => true, :save => true)
    end
  end

  task :process_combination_no_version, [:combination_id] => [:environment] do |t, args|
    if args[:combination_id].nil?
      combinations = Combination.all
    else
      combinations = [Combination.find(args[:combination_id])]
    end

    combinations.each do |combination| 
      combination.process(:with_version => false, :save => true)
    end
  end

  task process_unknown: :environment do
    combinations = Combination.where(:device => nil)
    combinations.each do |combination|
      combination.process(:with_version => true, :save => true)
    end
  end

  task :process_for_discoverer, [:discoverer_id] => [:environment] do |t, args|
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

  task create_base_admin: :environment do
    User.create!(:github_uid => "3857942", :name => 'TBD', :email => 'TBD', :level => 10)
  end

  task package: :environment do
    Package.new.build_and_release
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

  task delete_invalid_combinations: :environment do
    Combination.all.each do |c| 
      c.validate_combination_uniqueness
      if c.errors.size > 0
        puts "Deleting #{c.id}"
        c.delete
      end
    end
  end

  task generate_replace: :environment do
    devices = Device.where('created_at > ? or updated_at > ?', 1.week.ago, 1.week.ago)
    discoverers = Discoverer.where('created_at > ? or updated_at > ?', 1.week.ago, 1.week.ago)
    rules = Rule.where('created_at > ? or updated_at > ?', 1.week.ago, 1.week.ago)
    conditions = Condition.where('created_at > ? or updated_at > ?', 1.week.ago, 1.week.ago)

    objects = []
    objects << devices.all
    objects << discoverers.all
    objects << rules.all
    objects << conditions.all

    objects.flatten!

    puts objects.count

    objects.each do |o|
      query = "REPLACE into #{o.class.table_name} ("

      values = []
      o.attributes.each do |k,v|
        query += "#{k},"
        values << v
      end
      query = query[0...-1]
      query += ") VALUES("

      values.each do |v|
        v = ActiveRecord::Base.send(:sanitize_sql_array, ['?', v])
        query += "#{v},"
      end

      query = query[0...-1]
      query += ");"

      puts query
    end

  end

end
