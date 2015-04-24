class EventsController < ApplicationController
  def index
    @events = Event.all.limit(50).order('created_at DESC')

    respond_to do |format|
      format.rss { render :layout => false }
    end
  end
end
