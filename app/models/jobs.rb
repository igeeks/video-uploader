module Jobs
  
  class VideoUploadJob
    attr_accessor :video_id
    
    def initialize(options)
      @video_id = options["video_id"] || options[:video_id]
    end
    
    def perform(options = nil)
      video = Video.find(@video_id)
      
      logger ||= Rails && Rails.logger ? Rails.logger : Logger.new(STDOUT)
      logger.info "VideoUploadJob: vid #{video ? video.id : 'no video'}"
       
      if video.local_asset.file? 
        video.upload_to_s3
      end
    end
    
  end
  
  class VideoProcessJob
    attr_accessor :video_id
    
    def initialize(options)
      @video_id = options["video_id"] || options[:video_id]
    end
    
    def perform(options = nil)
      video = Video.find(@video_id)
      
      logger ||= Rails && Rails.logger ? Rails.logger : Logger.new(STDOUT)
      logger.info "VideoProcessJob: vid #{video ? video.id : 'no video'}"
       
      
      if video.asset.file? 
        video.send_to_zencoder
      else
        logger.info "VideoProcessJob: No video file on S3"
      end
    end
    
  end
 
end
