namespace :report do |ns|
  task :list do
    puts 'all tasks:'
    puts ns.tasks
  end

  task generate_in_events: :environment do
    Event.create(:title => "Today's Fingerbank stats", :value => "
      There are now #{Combination.unknown.count} unknown combinations
      There are now #{Device.where(:mobile => true).count} mobile devices
      There are now #{Device.where(:tablet => true).count} tablet devices
    ")
  end

end
