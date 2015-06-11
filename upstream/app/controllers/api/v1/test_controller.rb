class Api::V1::TestController < Api::ApiController
  def key
    # if we've made it here then the key is valid
    render :text => "Key is valid"
  end
end
