class VideosController < ApplicationController
  # GET /videos
  # GET /videos.xml
  
  layout :smart_layout
  
  def index
    @videos = Video.all
  
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @videos }
    end
  end

  # GET /videos/1
  # GET /videos/1.xml
  def show
    @video = Video.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @video }
      format.js   { render :json => @video.to_json }
    end
  end
  
  def data
    @video = Video.find(params[:id])
    logger.info(@video.current_state)
    @video.state = @video.state.humanize
    @video.thumbnail_url
    logger.info(@video.dimensions)
    render :json => @video.to_json
  end

  # GET /videos/new
  # GET /videos/new.xml
  def new
    @video = Video.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @video }
    end
  end

  # GET /videos/1/edit
  def edit
    @video = Video.find(params[:id])
  end

  def create
      @video = Video.new(params[:video])
      @video.thumbnail_count ||= 5
      @video.selected_thumbnail ||= 1
      @video.title ||= params['Filename']
      
      data = params['Filedata']
      @video.local_asset_file_name = params['Filename']
      @video.local_asset = data
      @video.local_asset_content_type = MIME::Types.type_for(data.original_filename).to_s
      
      @video.save
      
      # logger.info(@video.to_yaml)
      
      render :json => @video.to_json
      # respond_to do |format|
      #        if @video.save
      #          # flash[:notice] = 'Asset was successfully created.'
      # 
      #          # @video.send_to_zencoder
      #          format.js "true"
      #          format.html { redirect_to(@video) }
      #          format.xml  { render :xml => @video, :status => :created, :location => @video }
      #        else
      #          format.js "false"
      #          format.html { render :action => "new" }
      #          format.xml  { render :xml => @video.errors, :status => :unprocessable_entity }
      #        end
      #      end
    end

  # PUT /videos/1
  # PUT /videos/1.xml
  def update
    @video = Video.find(params[:id])

    respond_to do |format|
      if @video.update_attributes(params[:video])
        format.html { redirect_to(@video, :notice => 'Video was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @video.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /videos/1
  # DELETE /videos/1.xml
  def destroy
    @video = Video.find(params[:id])
    @video.destroy

    respond_to do |format|
      format.html { redirect_to(videos_url) }
      format.xml  { head :ok }
      format.js {head :ok}
    end
  end
  
  def smart_layout
    blank_actions = [:data,:show]
    blank_actions.include?(action_name.to_sym) ? 'blank' : 'application'
  end
  
end
