namespace :report do |ns|
  task :list do
    puts 'all tasks:'
    puts ns.tasks
  end

  task generate_in_events: :environment do
    Event.create(:value => "There are now #{Combination.unknown.count} unknown combinations")
    Event.create(:value => "There are now #{Device.where(:mobile => true)} mobile devices")
    Event.create(:value => "There are now #{Device.where(:tablet => true)} tablet devices")
  end

end
