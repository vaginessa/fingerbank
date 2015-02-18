class User < ActiveRecord::Base
  validates_presence_of :github_uid, :name
  validates_uniqueness_of :github_uid, :display_name

  has_many :combinations, :foreign_key => "submitter_id"
  has_many :watched_combinations
  has_many :devices, :foreign_key => "submitter_id"

  scope :admins, -> {where(:level => 10)}
  scope :api_submitters, -> {where(:level => 5)}
  scope :community, -> {where(:level => 0)}

  after_create :generate_key

  def self.MAX_TIMEFRAMED_REQUESTS
     return ENV['MAX_TIMEFRAMED_REQUESTS'].to_i || 10000
  end

  def self.LEVELS
    return {
      :admin => 10,
      :api_submitter => 5,
      :community => 0,
    }
  end

  def generate_key
    require 'digest/sha1'
    self.key = Digest::SHA1.hexdigest "API-#{Time.now}-#{github_uid}"
    self.save
  end

  def add_request
    if self.requests.nil?
      self.requests = 1
    else
      self.requests += 1
    end

    if self.timeframed_requests.nil?
      self.timeframed_requests = 1
    else
      self.timeframed_requests += 1
    end
    
    save!
  end

  def can_use_api
    request_number = self.timeframed_requests || 0
    if request_number < User.MAX_TIMEFRAMED_REQUESTS && !self.blocked 
      return true
    end
    return false
  end

  def self.from_omniauth(auth)
    user = self.where(:github_uid => auth.uid).first
    if user 
      user.update!(:github_uid => auth.uid, :name => auth.info.nickname, :display_name => auth.info.name, :email => auth.info.email)
    else
      create(:github_uid => auth.uid, :name => auth.info.nickname, :display_name => auth.info.name, :email => auth.info.email)
    end
    return self.where(:github_uid => auth.uid).first 
  end

  def promote_admin
    promote_to User.LEVELS[:admin]
  end

  def promote_submitter
    promote_to User.LEVELS[:api_submitter]
  end

  def promote_to(level)
    update(:level => level)
  end

  def demote_to(level)
    if User.admins.size > 1
      update(:level => level)
    else
      return false 
    end
  end

  def demote
    demote_to(0)
  end

  def admin?
    level >= 10
  end

  def api_submitter?
    level >= 5
  end 

end
