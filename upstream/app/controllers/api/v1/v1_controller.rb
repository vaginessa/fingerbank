class Api::V1::V1Controller < Api::ApiController
  skip_before_filter :ensure_admin

  before_filter :validate_key

  resource_description do
    eval(ApiDoc.v1_block)
  end

  def validate_key
    if Rails.cache.read("#{request.ip}-ban")
      render :json => "Temporary blacklist", :status => :forbidden
      return
    end

    if params[:key].nil?
      increment_fails
      render :json => "Missing key", :status => :unauthorized
      return
    end

    @current_user = User.where(:key => params[:key]).first
    if @current_user.nil?
      increment_fails
      render :json => "Invalid key", :status => :unauthorized
      return
    end

    if !@current_user.can_use_api
      if @current_user.reached_api_limit
        UserMailer.hourly_limit_reached(@current_user).deliver
      end
      increment_fails
      render :json => "Account blocked or max hourly limit reached.", :status => :forbidden
      return
    end

    @current_user.add_request

  end

  def increment_fails
    max_requests = 5
    throttle_time = 1.minute

    fails = Rails.cache.read("#{request.ip}-count") || 0
    logger.info "Incrementing fails for #{request.ip}"
    Rails.cache.write("#{request.ip}-count", fails+1, :expires_in => throttle_time)
    
    if Rails.cache.read("#{request.ip}-count") >= 5
      logger.info "Banning #{request.ip} for #{throttle_time}"
      Rails.cache.write("#{request.ip}-ban", 'Too mucb failures', :expires_in => throttle_time)
    end
  end

end
