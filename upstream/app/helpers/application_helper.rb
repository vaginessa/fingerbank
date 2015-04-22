module ApplicationHelper
  def bootstrap_class_for flash_type
    case flash_type
      when 'success'
        "alert-success"
      when 'error'
        "alert-danger"
      when 'alert'
        "alert-block"
      when 'notice'
        "alert-info"
      else
        flash_type.to_s
    end
  end

  def current_user_admin?
    @current_user && @current_user.admin?
  end

  def new_combinations(from_when = 1.day.ago)
    Combination.where('created_at > ?', from_when)
  end

  def new_user_agents(from_when = 1.day.ago)
    UserAgent.where('created_at > ?', from_when)
  end

  def average_response_time
    return `awk '/interogate/,/Completed/' #{Rails.root}/log/production.log | egrep 'Completed (200|404)' | egrep -o 'OK in [0-9.]+' | egrep -o '[0-9.]+' | awk '{s+=$1; count+=1} END {print s/count}'`
  end

  def devices_discovered(from_when = 20.year.ago)
    devices = []
    Device.all.each do |d|
      if !d.combinations.empty? && !devices.include?(d) && !d.combinations.where('created_at > ?', from_when).empty? && d.combinations.where('created_at < ?', from_when).empty?
        devices << d
      end
    end
    devices
  end

end
