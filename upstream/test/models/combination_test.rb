require 'test_helper'

class CombinationTest < ActiveSupport::TestCase
  test 'fixtures are there' do
    assert combinations(:iphone).user_agent.value == 'Mozilla/5.0 (iPhone; CPU iPhone OS 7_1_2 like Mac OS X) AppleWebKit/537.51.2 (KHTML, like Gecko) GSA/5.2.43972 Mobile/11D257 Safari/9537.53'
  end

  test 'combination lookup without cache' do
    FingerbankCache.clear
    combination = combinations(:iphone)
    assert combination.process(:with_version => true, :save => true), "iPhone combination can be processed"
    assert combination.processed_method == 'find_matching_discoverers_long'
    assert combination.device.name == 'iPhone', "iPhone combination yields the right result"

    FingerbankCache.clear
    combination = combinations(:android)
    assert combination.process(:with_version => true, :save => true), "Android combination can be processed"
    assert combination.processed_method == 'find_matching_discoverers_long'
    assert combination.device.name == 'Nexus zammit', "Android combination yields the right result"

    # We're supposed to send e-mails when having full cache miss
    assert ActionMailer::Base.deliveries.size == 2
  end

  test 'combination lookup with cache discoverers cache' do
    FingerbankCache.clear
    assert Discoverer.device_matching_discoverers.keys.empty?, "Discoverers cache is empty when cache is emptied"
    Discoverer.fbcache
    assert !Discoverer.device_matching_discoverers.keys.empty?, "Discoverers cache is filled up after the build"
    combination = combinations(:iphone)
    assert Discoverer.device_matching_discoverers[combination.id], "Valid known combination will yield in discoverers cache"
    assert !Discoverer.device_matching_discoverers['zammit'], "Invalid id will not yield in discoverers cache"
    assert combination.process(:with_version => true, :save => true), "iPhone combination can be processed"
    assert combination.processed_method == 'find_matching_discoverers_cache'
  end

  test 'combination lookup with discoverers ifs' do
    # we create a new combination with a new user agent
    user_agent = UserAgent.create!(:value => 'Mozilla/5.0 (Linux; Android 4.1.2; SGH-T599N Build/JZO54K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.86 Mobile Safari/537.36')
    combination = Combination.create!(:user_agent => user_agent, :dhcp_vendor => dhcp_vendors(:empty), :dhcp_fingerprint => dhcp_fingerprints(:empty))
    assert combination.process(:with_version => true, :save => true), "New android combination can be processed"
    assert combination.processed_method == "find_matching_discoverers_tmp_table"
    
  end

  test 'combination lookup with version' do
    combination = combinations(:iphone)
    Discoverer.fbcache
    combination.process(:with_version => true, :save => true)
    assert combination.version == '7.1.2', "version has been detected properly (#{combination.version})"     
  end
end
