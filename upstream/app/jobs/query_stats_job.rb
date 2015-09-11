class QueryStatsJob < ActiveJob::Base
  queue_as :default

  def perform(args)
    logger.info "Recording query statistics"
    return QueryLog.create(:user => args[:user], :combination => args[:combination])
  end
end
