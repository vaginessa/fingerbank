class AdminMailer< ActionMailer::Base
  default from: "fingerbank@inverse.ca"
  default to: ENV['ADMIN_EMAIL']

  def discoverers_cache_miss
    now = Time.now
    warned_at = Rails.cache.fetch("mail-discoverers_cache_miss", :expires_in => 20.minute) {Time.now}
    if warned_at > now 
      mail(subject: "Full cache miss on discoverers !")
    end
  end

  def package_failed
    mail(subject: "Fingerbank database build failed !", :body => "Check server side logs for details.")
  end

  def daily_report
    @events = Event.where('created_at > ?', 1.day.ago).order('created_at ASC')
    mail(subject: "Fingerbank daily event report")
  end

end
