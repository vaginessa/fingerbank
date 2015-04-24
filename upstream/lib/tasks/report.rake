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

end
