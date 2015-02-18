class WatchedCombinationsController < ApplicationController
  before_action :set_user

  skip_before_filter :ensure_admin
  before_filter :admin_or_current_user

  def index
    @watched_combinations = @user.watched_combinations
  end

  def create
    @combination = Combination.find(params[:combination_id])
    @watched_combination = WatchedCombination.new(:user => @user, :combination => @combination)
    if @watched_combination.save
      redirect_to :back, :notice => "Combination successfully watched" 
    else
      redirect_to :back, :error => "Combination could not be watched #{@watched_combination.errors}"
    end
  end

  def destroy
    @watched_combination = WatchedCombination.find(params[:id])
    @watched_combination.destroy
    respond_to do |format|
      format.html { redirect_to :back, notice: 'Combination was successfully unwatched.' }
      format.json { head :no_content }
    end
  end

  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def watched_combination_params
      params.require(:combination).permit(:combination_id)
    end

    def set_user
      @user = User.find(params[:user_id])
    end



end
