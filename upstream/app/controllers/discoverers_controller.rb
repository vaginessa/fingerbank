class DiscoverersController < ApplicationController
  skip_before_filter :ensure_admin, only: [:cache]
  before_action :set_discoverer, only: [:show, :edit, :update, :destroy]

  def cache
    FingerbankCache.get('device_matching_discoverers')
    FingerbankCache.get('ifs_for_discoverers')
    FingerbankCache.get('ifs_association_for_discoverers')
    render text: 'ok'
  end

  # GET /discoverers
  # GET /discoverers.json
  def index
    if params[:search]
      @discoverers = Discoverer.simple_search(params[:search])
    else
      @discoverers = Discoverer.all
    end
    @discoverers = @discoverers.paginate(:page => params[:page], :per_page => 50)
  end

  # GET /discoverers/1
  # GET /discoverers/1.json
  def show
  end

  # GET /discoverers/new
  def new
    @discoverer = Discoverer.new
    if device_id_param
     @discoverer.device = Device.find(device_id_param) 
    end 
  end

  # GET /discoverers/1/edit
  def edit
  end

  # POST /discoverers
  # POST /discoverers.json
  def create
    @discoverer = Discoverer.new(discoverer_params)

    respond_to do |format|
      if @discoverer.save
        format.html { redirect_to @discoverer, notice: 'Discoverer was successfully created.' }
        format.json { render :show, status: :created, location: @discoverer }
      else
        format.html { render :new }
        format.json { render json: @discoverer.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /discoverers/1
  # PATCH/PUT /discoverers/1.json
  def update
    respond_to do |format|
      if @discoverer.update(discoverer_params)
        format.html { redirect_to @discoverer, notice: 'Discoverer was successfully updated.' }
        format.json { render :show, status: :ok, location: @discoverer }
      else
        format.html { render :edit }
        format.json { render json: @discoverer.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /discoverers/1
  # DELETE /discoverers/1.json
  def destroy
    @discoverer.destroy
    respond_to do |format|
      format.html { redirect_to discoverers_url, notice: 'Discoverer was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_discoverer
      @discoverer = Discoverer.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def discoverer_params
      params.require(:discoverer).permit(:description, :priority, :device_id, :version, :device_rule_ids => [], :version_rule_ids => [])
    end

    def device_id_param
      params[:device_id]
    end

end
