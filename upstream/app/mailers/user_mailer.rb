class UserMailer < ActionMailer::Base
  default from: "fingerbank@inverse.ca"
  default to: "support@inverse.ca"

  def request_api_submission(user)
    @user = user
    mail(subject: "Request to submit to the fingerbank API")
  end
end
