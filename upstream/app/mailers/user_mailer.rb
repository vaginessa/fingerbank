class UserMailer < ActionMailer::Base
  default from: "fingerbank@inverse.ca"
  default to: "support@inverse.ca"

  def request_api_submission(user)
    @user = user
    mail(subject: "Request to submit to the fingerbank API")
  end

  def user_blocked(user)
    @user = user
    mail(to: @user.email, reply_to: "support@inverse.ca", subject: "Your fingerbank account has been blocked.")
  end
end
