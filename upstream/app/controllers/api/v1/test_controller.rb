class Api::V1::TestController < Api::V1::V1Controller
  def key
    # if we've made it here then the key is valid
    render :text => "Key is valid"
  end
end
