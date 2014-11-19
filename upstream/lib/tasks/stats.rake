
namespace :stats do
  task new_devices: :environment do
    Combination.where("created_at > ?", 1.day.ago).each do |c| puts c.device ? c.device.name : '' end
  end

  task num_android_devices: :environment do
    Device.where(:name => "Generic Android").childs.count
  end
end
