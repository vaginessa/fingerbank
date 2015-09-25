class Api::V1::StaticController < Api::V1::V1Controller

  resource_description do
    eval(ApiDoc.v1_block)
  end

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
  
  api :GET, '/download'

  desc 'This method allows you to download the latest version of the Fingerbank database to use with the local instance of Fingerbank or another application.'

  formats ['Request : */*', 'Response : application/sqlite3']
  def download
    db_fname = Rails.root.join('db', 'package', "packaged.sqlite3")
    send_file(db_fname, :filename => "packaged.sqlite3", :type => "application/x-sqlite3")
  end

  api :GET, '/download-p0f-map'

  desc 'This method allows you to download the latest version of the p0f map that is compatible with the Fingerbank library'

  formats ['Request : */*', 'Response : text/plain']
  def download_p0f_map
    db_fname = Rails.root.join('db', 'package', "p0f-fingerbank.fp")
    send_file(db_fname, :filename => "p0f-fingerbank.fp", :type => "text/plain")
  end

end
