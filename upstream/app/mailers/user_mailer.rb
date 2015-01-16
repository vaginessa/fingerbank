class UserMailer < ActionMailer::Base
  default from: "jsemaan@inverse.ca"
  default to: "jsemaan@inverse.ca"

  def request_api_submission(user)
    @user = user
    mail(subject: "Request to submit to the API")
  end
end
