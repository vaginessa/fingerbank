class Api::V1::CombinationsController < Api::ApiController
  
  def interogate 
    require 'json'

    interogate_params = get_interogate_params

    interogate_params[:dhcp_fingerprint] = interogate_params[:dhcp_fingerprint] || ""
    interogate_params[:user_agent] = interogate_params[:user_agent] || ""
    interogate_params[:dhcp_vendor] = interogate_params[:dhcp_vendor] || ""
    interogate_params[:mac] = interogate_params[:mac] || ""

    puts interogate_params

    if interogate_params[:user_agent].blank? && interogate_params[:dhcp_fingerprint].blank? && interogate_params[:dhcp_vendor].blank? && interogate_params[:mac].blank?
      render json: {:message => 'There is no parameter in your query'}, :status => :bad_request
      return
    end

    @combination = nil
    user_agent = UserAgent.where(:value => interogate_params[:user_agent]).first
    user_agent = UserAgent.create(:value => interogate_params[:user_agent]) unless user_agent
    puts "Matched UA #{user_agent.id} : #{user_agent.value}"

    dhcp_fingerprint = DhcpFingerprint.where(:value => interogate_params[:dhcp_fingerprint]).first
    dhcp_fingerprint = DhcpFingerprint.create(:value => interogate_params[:dhcp_fingerprint]) unless dhcp_fingerprint
    puts "Matched DHCP fingerprint #{dhcp_fingerprint.id} : #{dhcp_fingerprint.value}"

    dhcp_vendor = DhcpVendor.where(:value => interogate_params[:dhcp_vendor]).first
    dhcp_vendor = DhcpVendor.create(:value => interogate_params[:dhcp_vendor]) unless dhcp_vendor
    puts "Matched DHCP vendor #{dhcp_vendor.id} : #{dhcp_vendor.value}"

    mac_vendor = MacVendor.from_mac(interogate_params[:mac])
    mac_vendor_id = mac_vendor.nil? ? 'NULL' : mac_vendor.id

    @combination = Combination.where(:user_agent =>user_agent, :dhcp_fingerprint => dhcp_fingerprint, :dhcp_vendor_id => dhcp_vendor, :mac_vendor => mac_vendor).first

    respond_to do |format|
      if @combination.nil?
        @combination = Combination.create!(:user_agent => user_agent, :dhcp_fingerprint => dhcp_fingerprint, :dhcp_vendor => dhcp_vendor, :mac_vendor => mac_vendor, :submitter => @current_user)
        @combination.process
      end
      format.json { render 'combinations/show', status: :found, location: @combination }
    end
  end

  private
    def get_interogate_params
      params.permit(:user_agent, :dhcp_fingerprint, :dhcp_vendor, :mac)
    end

end
