class Api::ApiController < ApplicationController

  protect_from_forgery with: :null_session

  skip_before_filter :ensure_admin

  before_filter :validate_key

  def validate_key
    if params[:key].nil?
      render :json => "Missing key", :status => :unauthorized
      return
    end

    @current_user = User.where(:key => params[:key]).first
    if @current_user.nil?
      render :json => "Invalid key", :status => :unauthorized
      return
    end

    if !@current_user.can_use_api
      if @current_user.reached_api_limit
        UserMailer.hourly_limit_reached(@current_user).deliver
      end
      render :json => "Account blocked or max hourly limit reached.", :status => :forbidden
      return
    end

    @current_user.add_request

  end

end
