require "#{Rails.root}/app/helpers/application_helper"
include ApplicationHelper

namespace :report do |ns|
  task :list do
    puts 'all tasks:'
    puts ns.tasks
  end

  task generate_in_events: :environment do
    Event.create(:title => "Daily Fingerbank report", :value => "
      There are now #{Combination.count} combinations in total
      There are now #{Combination.unknown.count} unknown combinations
      There are now #{Device.where(:mobile => true).count} mobile devices
      There are now #{Device.where(:tablet => true).count} tablet devices
      There were #{new_combinations(1.day.ago).size} new combinations discovered in the last 24 hours
      There were #{new_user_agents(1.day.ago).size} new user agents discovered in the last 24 hours
      The average combination score is : #{Combination.average(:score).round}
      The average response time for the API is : #{average_response_time}
    ")
  end

  task mail_daily: :environment do
    AdminMailer.daily_report.deliver
  end

  task :new_dhcp_discoverers, [:after] => [:environment] do |t, args|
    unless args[:after]
      puts "Missing start date"
    end
    rules = Rule.where('created_at > ?', args[:after]).where('value like "%dhcp_fingerprints%"')
    rules.each do |rule| 
      if rule.device_discoverer 
        puts "----------------"
        puts rule.device_discoverer.device.full_path
        puts rule.value 
      end
    end
  end

  task dhcp_fingerprint_2_device: :environment do
    fingerprint2device = {}
    vendor2device = {}
    DhcpFingerprint.all.each do |fingerprint|
      fingerprint_devices = fingerprint.combinations.group(:dhcp_vendor_id).map { |c| 
        c.device.full_path unless c.dhcp_vendor.value.empty? || c.dhcp_vendor.value.nil? || c.device.nil? 
      }
      fingerprint_devices = fingerprint_devices.uniq
      fingerprint_devices.delete(nil)

      fingerprint2device[fingerprint.value] = fingerprint_devices unless fingerprint_devices.size < 2

    end
    require 'pp'
    pp fingerprint2device
  end

  task dhcp_fingerprint_2_vendor: :environment do
    fingerprint2vendor = {}
    DhcpFingerprint.all.each do |fingerprint|
      tmp_vendors = fingerprint.combinations.group(:dhcp_vendor_id).map { |c| 
        c.dhcp_vendor.value unless c.dhcp_vendor.value.empty? || c.dhcp_vendor.value.nil? 
      }

      vendors = []
      added_dhcpcd = false
      added_xerox = false
      added_hp = false
      added_bb = false
      added_udhcp = false
      added_linux = false
      tmp_vendors.each do |vendor|
        if vendor =~ /^dhcpcd-.*/i
          vendors << vendor if !added_dhcpcd 
          added_dhcpcd = true
          next
        end
        if vendor =~ /^mf(g|f)=Xerox.*/i || vendor =~ /^mfg=fujixerox.*/i
          vendors << vendor if !added_xerox
          added_xerox = true
          next
        end
        if vendor =~ /^mfg=Hewlett.*/i
          vendors << vendor if !added_hp
          added_hp = true
          next
        end
        if vendor =~ /^blackberry.*/i
          vendors << vendor if !added_bb
          added_bb = true
          next
        end
        if vendor =~ /^udhcp.*/i
          vendors << vendor if !added_udhcp
          added_udhcp = true
          next
        end
        if vendor =~ /^Linux.*/i
          vendors << vendor if !added_linux
          added_linux = true
          next
        end

        vendors << vendor
      end
      
      fingerprint2vendor[fingerprint.value] = vendors unless vendors.size < 2

    end
    require 'pp'
    pp fingerprint2vendor
  end

end
