class DeleteTempCombinationJob < ActiveJob::Base
  queue_as :default

  def perform(temp_combination)
    logger.info "Deleting temp combination #{temp_combination.id}"
    return temp_combination.delete
  end
end
