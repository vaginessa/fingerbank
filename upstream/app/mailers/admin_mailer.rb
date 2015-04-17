class AdminMailer< ActionMailer::Base
  default from: "fingerbank@inverse.ca"
  default to: ENV['ADMIN_EMAIL']

  def discoverers_cache_miss
    now = Time.now
    warned_at = Rails.cache.fetch("mail-discoverers_cache_miss", :expires_in => 20.minute) {Time.now}
    if warned_at > now || 1
      mail(subject: "Full cache miss on discoverers !")
    end
  end

end
