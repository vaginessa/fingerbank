class QueryLog < ActiveRecord::Base
  validates_presence_of :user_id
  validates_presence_of :combination_id

  belongs_to :combination
  belongs_to :user

  validates_uniqueness_of :user_id, :scope => [ :combination_id ], :message => "A query log with the same information already exists"


end
