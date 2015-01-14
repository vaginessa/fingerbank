class Api::ApiController < ApplicationController

  protect_from_forgery with: :null_session

  skip_before_filter :ensure_admin

  before_filter :validate_key

  def validate_key
    if params[:key].nil?
      render :json => "Missing key", :status => :unauthorized
      return
    end

    user = User.where(:key => params[:key]).first
    if user.nil?
      render :json => "Invalid key", :status => :unauthorized
      return
    end

    if !user.can_use_api
      render :json => "Account blocked or max hourly limit reached.", :status => :forbidden
      return
    end

    user.add_request

  end

end
