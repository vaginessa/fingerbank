class Api::V1::CombinationsController < Api::ApiController

  def submit
    params = get_submit_params
    submit_params = {}
    submit_params[:user_agent] = params[:user_agent] || []
    submit_params[:dhcp_fingerprint] = params[:dhcp_fingerprint] || []
    submit_params[:dhcp_vendor] = params[:dhcp_vendor] || []

    logger.debug "Submit params : #{submit_params.inspect}"

    empty_user_agent = UserAgent.find(0)
    empty_dhcp_fingerprint = DhcpFingerprint.find(0)
    empty_dhcp_vendor = DhcpVendor.find(0)

    added = {:user_agent => [], :dhcp_fingerprint => [], :dhcp_vendor => []}

    submit_params[:user_agent].each do |user_agent|
      unless UserAgent.exists?(:value => user_agent)
        logger.info "User agent #{user_agent} doesn't exist. Creating it"
        user_agent = UserAgent.create(:value => user_agent)
        Combination.create(:user_agent => user_agent, :submitter => @current_user)
        added[:user_agent] << user_agent.value
      end
    end

    submit_params[:dhcp_fingerprint].each do |dhcp_fingerprint|
      unless DhcpFingerprint.exists?(:value => dhcp_fingerprint)
        logger.info "DHCP fingerprint #{dhcp_fingerprint} doesn't exist. Creating it"
        dhcp_fingerprint = DhcpFingerprint.create(:value => dhcp_fingerprint)
        Combination.create(:dhcp_fingerprint => dhcp_fingerprint, :submitter => @current_user)
        added[:dhcp_fingerprint] << dhcp_fingerprint.value
      end
    end

    submit_params[:dhcp_vendor].each do |dhcp_vendor|
      unless DhcpVendor.exists?(:value => dhcp_vendor)
        logger.info "DHCP vendor #{dhcp_vendor} doesn't exist. Creating it"
        dhcp_vendor = DhcpVendor.create(:value => dhcp_vendor)
        Combination.create(:dhcp_vendor => dhcp_vendor, :submitter => @current_user)
        added[:dhcp_vendor] << dhcp_vendor.value
      end
    end
    
    render :json => added
  end
  
  def interogate 
    require 'json'

    interogate_params = get_interogate_params

    interogate_params[:dhcp_fingerprint] = interogate_params[:dhcp_fingerprint] || ""
    interogate_params[:user_agent] = interogate_params[:user_agent] || ""
    interogate_params[:dhcp_vendor] = interogate_params[:dhcp_vendor] || ""
    interogate_params[:mac] = interogate_params[:mac] || ""

    logger.debug "Interogate params : #{interogate_params.inspect}"

    if interogate_params[:user_agent].blank? && interogate_params[:dhcp_fingerprint].blank? && interogate_params[:dhcp_vendor].blank? && interogate_params[:mac].blank?
      render json: {:message => 'There is no parameter in your query'}, :status => :bad_request
      return
    end

    @combination = nil
    user_agent = UserAgent.where(:value => interogate_params[:user_agent]).first
    user_agent = UserAgent.create(:value => interogate_params[:user_agent]) unless user_agent
    logger.info "Matched UA #{user_agent.id} : #{user_agent.value}"

    dhcp_fingerprint = DhcpFingerprint.where(:value => interogate_params[:dhcp_fingerprint]).first
    dhcp_fingerprint = DhcpFingerprint.create(:value => interogate_params[:dhcp_fingerprint]) unless dhcp_fingerprint
    logger.info "Matched DHCP fingerprint #{dhcp_fingerprint.id} : #{dhcp_fingerprint.value}"

    dhcp_vendor = DhcpVendor.where(:value => interogate_params[:dhcp_vendor]).first
    dhcp_vendor = DhcpVendor.create(:value => interogate_params[:dhcp_vendor]) unless dhcp_vendor
    logger.info "Matched DHCP vendor #{dhcp_vendor.id} : #{dhcp_vendor.value}"

    mac_vendor = MacVendor.from_mac(interogate_params[:mac])
    mac_vendor_id = mac_vendor.nil? ? 'NULL' : mac_vendor.id

    @combination = Combination.where(:user_agent =>user_agent, :dhcp_fingerprint => dhcp_fingerprint, :dhcp_vendor_id => dhcp_vendor, :mac_vendor => mac_vendor).first

    if @combination.nil?
      logger.warn "Combination doesn't exist. Creating a new one"
      @combination = Combination.new(:user_agent => user_agent, :dhcp_fingerprint => dhcp_fingerprint, :dhcp_vendor => dhcp_vendor, :mac_vendor => mac_vendor, :submitter => @current_user)
      @combination.process(:with_version => true, :save => false)
    end
    if @combination.device.nil?
      logger.warn "Combination didn't yield any device."
      @combination.save if @current_user.api_submitter?
      render json: @combination, :status => 404
    else
      logger.info "Combination processed correctly."
      if params[:debug] == "on"
        combination_hash = @combination.attributes 
        combination_hash[:device] = @combination.device.attributes
        combination_hash[:device][:parents] = @combination.device.parents
        render json: combination_hash
      else
        render 'combinations/show.json'
      end
    end
  end

  private
    def get_interogate_params
      params.permit(:user_agent, :dhcp_fingerprint, :dhcp_vendor, :mac)
    end

    def get_submit_params
      params.permit(:user_agent => [], :dhcp_fingerprint => [], :dhcp_vendor => [])
    end

end
