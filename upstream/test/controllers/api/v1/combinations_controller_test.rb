require 'test_helper'
require 'json'

class Api::V1::CombinationsControllerTest < ActionController::TestCase

  def setup
    @admin_user = users(:julsemaan)
    @blocked_user = users(:blocked_user)
    @user = users(:normal_user)
  end

  test "should be able to lookup an existing combination" do
    combination = combinations(:iphone)
    combination.process
    post :interogate, {:user_agent => combination.user_agent.value, :key => @user.key}
    result = JSON.parse @response.body
    assert result['id'] == combination.id, "Queried combination is the one that already existed"
    assert result['device']['id'] == combination.device.id, "Queried combination has the same device"
  end

  test "should be able to lookup a new combination" do
    user_agent = "Mozilla/Dinde iPhone"
    post :interogate, {:user_agent => user_agent, :key => @user.key}
    result = JSON.parse @response.body
    assert result['device']['id'] == devices(:iphone).id, "Device is properly discovered"
  end

  test "shouldn't access the API without a valid key" do
    # without a key
    post :interogate, {:user_agent => 'Dinde/5.0'}
    assert @response.code == "401", "Need a key to access the API"

    # with an invalid key
    post :interogate, {:user_agent => 'Dinde/5.0', :key => 'this-is-invalid!'}
    assert @response.code == "401", "Invalid key shouldn't have access to the API"
  end

  test "normal user shouldn't submit unprocessable data" do
    value = 'sdfjkhaskdindefnyasdifsdf'
    post :interogate, {:user_agent => value, :key => @user.key}
    assert @response.code == "404", "Unknown combination should yield a 404"
    assert !(Combination.exists?(:user_agent => UserAgent.where(:value => value).first)), "Unknown combination shouldn't be saved if submitted by a normal user"
  end

  test "api submitter should be able to submit unprocessable data" do
    value = '1234567890'
    post :interogate, {:user_agent => value, :key => @admin_user.key}
    assert @response.code == "404", "Unknown combination should yield a 404"
    assert (Combination.exists?(:user_agent => UserAgent.where(:value => value).first)), "Unknown combination should be saved if submitted by at least an API submitter"
  end

  test "blocked user shouldn't access the API" do
    post :interogate, {:user_agent => "test", :key => @blocked_user.key}
    assert @response.code == "403", "Blocked user should be given a 403"
  end

  test "user cannot go above timeframed limit" do
    @user.update(:timeframed_requests => User.MAX_TIMEFRAMED_REQUESTS+1)
    post :interogate, {:user_agent => 'test', :key => @user.key}
    assert @response.code == "403", "User above the timeframed limit should have a 403"
  end
end
