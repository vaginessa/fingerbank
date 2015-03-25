class Api::V1::StaticController < Api::ApiController

  def validate_key
    if !ENV['PACKETFENCE_KEY'].nil? && params[:key] == ENV['PACKETFENCE_KEY']
      record_anonymous_user
      return
    end 
    super
  end

  def record_anonymous_user
      date = Time.now
      open(ENV['ANONYMOUS_STATS_FILE'], 'a') do |f|
        f.puts "#{date},#{params[:key]},#{controller_name}/#{action_name},#{request.remote_addr}"
      end 
  end
  
  def download
    db_fname = Rails.root.join('db', 'package', "packaged.sqlite3")
    send_file(db_fname, :filename => "packaged.sqlite3", :type => "application/x-sqlite3")
  end
end
