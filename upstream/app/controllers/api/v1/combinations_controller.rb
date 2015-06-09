class Api::V1::CombinationsController < Api::V1::V1Controller

  resource_description do
    eval(ApiDoc.v1_block)
  end


  api :POST, '/combinations/submit'

  desc 'This method allows you to submit data to Fingerbank. It will not compute the details about the information you submit.'

  param :user_agent, Array, :of => String,
    :desc => "The User Agents to process", 
    :meta => {'Type' => "payload"}

  param :dhcp_fingerprint, Array, :of => String,
    :desc => "The DHCP fingerprints to process", 
    :meta => {'Type' => "payload"}

  param :dhcp_vendor, Array, :of => String,
    :desc => "The DHCP vendors to process", 
    :meta => {'Type' => "payload"}

  formats ['Request : application/json', 'Response : application/json']
  example %{
  Example body:
  {"dhcp_fingerprint":["1,15,3,6,44,46,47,31,33,121,249,43","1,15,3,6,44,32"]}
  }
  example %{
  Example response:
  {
    "dhcp_fingerprint" : [
      "1,15,3,6,44,32"
    ]
  }
  }
  example %{
  Example using curl:
  curl -X POST -d "{\\"dhcp_fingerprint\\":[\\"1,15,3,6,44,46,47,31,33,121,249,43\\",\\"1,15,3,6,44,32\\"]}" --header "Content-type: application/json" https://fingerbank.inverse.ca/api/v1/combinations/submit?key=
  }
  def submit
    params = get_submit_params
    submit_params = {}
    submit_params[:user_agent] = params[:user_agent] || []
    submit_params[:dhcp_fingerprint] = params[:dhcp_fingerprint] || []
    submit_params[:dhcp6_fingerprint] = params[:dhcp6_fingerprint] || []
    submit_params[:dhcp_vendor] = params[:dhcp_vendor] || []

    logger.debug "Submit params : #{submit_params.inspect}"

    empty_user_agent = UserAgent.find(0)
    empty_dhcp_fingerprint = DhcpFingerprint.find(0)
    empty_dhcp_vendor = DhcpVendor.find(0)

    added = {:user_agent => [], :dhcp_fingerprint => [], :dhcp6_fingerprint => [], :dhcp_vendor => []}

    submit_params[:user_agent].each do |user_agent|
      unless UserAgent.exists?(:value => user_agent)
        logger.info "User agent #{user_agent} doesn't exist. Creating it"
        combination = Combination.get_or_create(:user_agent => user_agent)
        combination.update(:submitter => @current_user)
        added[:user_agent] << user_agent
      end
    end

    submit_params[:dhcp_fingerprint].each do |dhcp_fingerprint|
      unless DhcpFingerprint.exists?(:value => dhcp_fingerprint)
        logger.info "DHCP fingerprint #{dhcp_fingerprint} doesn't exist. Creating it"
        combination = Combination.get_or_create(:dhcp_fingerprint => dhcp_fingerprint)
        combination.update(:submitter => @current_user)
        added[:dhcp_fingerprint] << dhcp_fingerprint
      end
    end

    submit_params[:dhcp6_fingerprint].each do |dhcp6_fingerprint|
      unless Dhcp6Fingerprint.exists?(:value => dhcp6_fingerprint)
        logger.info "DHCP6 fingerprint #{dhcp6_fingerprint} doesn't exist. Creating it"
        combination = Combination.get_or_create(:dhcp6_fingerprint => dhcp6_fingerprint)
        combination.update(:submitter => @current_user)
        added[:dhcp6_fingerprint] << dhcp6_fingerprint
      end
    end

    submit_params[:dhcp_vendor].each do |dhcp_vendor|
      unless DhcpVendor.exists?(:value => dhcp_vendor)
        logger.info "DHCP vendor #{dhcp_vendor} doesn't exist. Creating it"
        combination = Combination.get_or_create(:dhcp_vendor => dhcp_vendor)
        combination.update(:submitter => @current_user)
        added[:dhcp_vendor] << dhcp_vendor
      end
    end
  
    render :json => added
  end
  
  api :POST, '/combinations/interogate'

  desc 'This method allows you to interogate the Fingerbank database with a device information and get the details about it.'

  param :debug, String, 
    :desc => "Whether or not to add additionnal debug information in the response. 'on' activates it", 
    :meta => {'Type' => "URL"}

  param :user_agent, String, 
    :desc => "The User Agent of the device", 
    :meta => {'Type' => "payload"}

  param :dhcp_fingerprint, String, 
    :desc => "The DHCP fingerprint of the device", 
    :meta => {'Type' => "payload"}

  param :dhcp_vendor, String, 
    :desc => "The DHCP vendor of the device", 
    :meta => {'Type' => "payload"}

  param :mac, String, 
    :desc => "The MAC address of the device", 
    :meta => {'Type' => "payload"}

  error 404, "No device was found the the specified combination. It will be added to the unknown combinations list if you are part of the approved API submitters."

  formats ['Request : application/json', 'Response : application/json']
  example %{
  Example body:
  {"dhcp_fingerprint":"1,15,3,6,44,46,47,31,33,121,249,43"}
  }
  example %{
  Example response:
  {
      "created_at": "2014-10-13T03:14:45.000Z", 
      "device": {
          "created_at": "2014-09-09T15:09:51.000Z", 
          "id": 33, 
          "inherit": null, 
          "mobile?": false, 
          "name": "Microsoft Windows Vista/7 or Server 2008 (Version 6.0)", 
          "parent_id": 1, 
          "parents": [
              {
                  "approved": true, 
                  "created_at": "2014-09-09T15:09:50.000Z", 
                  "id": 1, 
                  "inherit": null, 
                  "mobile": null, 
                  "name": "Windows", 
                  "parent_id": null, 
                  "submitter_id": null, 
                  "tablet": null, 
                  "updated_at": "2014-09-09T15:09:50.000Z"
              }
          ], 
          "updated_at": "2014-09-09T15:09:52.000Z"
      }, 
      "id": 5733, 
      "score": 50, 
      "updated_at": "2014-11-13T17:39:36.000Z", 
      "version": null
  } 
  }
  example %{
  Example using curl:
  curl -X GET -d "{\\"dhcp_fingerprint\\":\\"1,15,3,6,44,46,47,31,33,121,249,43\\"}" --header "Content-type: application/json" https://fingerbank.inverse.ca/api/v1/combinations/interogate?key=
  }
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

    beginning_time = Time.now
    @combination = Combination.get_or_create(:user_agent => interogate_params[:user_agent], :dhcp_fingerprint => interogate_params[:dhcp_fingerprint], :dhcp_vendor_id => interogate_params[:dhcp_vendor], :mac => interogate_params[:mac]).first
    end_time = Time.now
    logger.info "Time elapsed for combination lookup #{(end_time - beginning_time)*1000} milliseconds"  

    if @combination.just_created
      logger.warn "Combination didn't exist and was created."
      @combination.update(:submitter => @current_user)
      @combination.process(:with_version => true, :save => true)
    end
    if @combination.device.nil?
      logger.warn "Combination didn't yield any device."
      @combination.destroy unless @current_user.api_submitter?
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
