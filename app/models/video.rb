class Video < ActiveRecord::Base
  belongs_to :post
  
  default_scope :order => "created_at DESC"
  
  after_create :queue_upload_to_s3
  before_destroy :delete_zc_generated_files
  
  attr_accessor :thumbnail_url, :duration_in_words, :dimensions
  
  ZENCODER_API_KEY = "YOUR_ZENCODER_API_KEY"
  S3_CREDENTIALS = "#{RAILS_ROOT}/config/amazon_s3.yml"
  S3_BUCKET = "YOUR_BUCKET_HERE"
   
  has_attached_file :local_asset
  has_attached_file :asset, :storage => :s3,
      :s3_credentials => S3_CREDENTIALS,
      :path => ":attachment/:id/:style/:basename.:extension",
      :bucket => S3_BUCKET
  
  validates_attachment_presence :local_asset
  
  state_machine :initial => :pending do
    state :uploading, :uploaded, :transcoding, :failed, :complete

    event :upload do
      transition [:pending] => :uploading
    end
    
    event :uploaded do
      transition [:pending, :uploading] => :uploaded
    end

    event :transcode do
      transition :uploaded => :transcoding
    end

    event :fail do
      transition any => :failed
    end

    event :complete do
      transition [:transcoding, :complete] => :complete
    end
  
  end
  
  def thumbnail_url
    thumbnail_urls[selected_thumbnail - 1] || thumbnail_urls.first
  end
  
  def thumbnail_urls
    if self.asset
      urls = []
      (1..self.thumbnail_count).each do |i|
        urls << "http://s3.amazonaws.com/#{self.asset.bucket_name}/assets/#{self.id}/thumbnails/thumb_000#{i -1}.png"
      end
    end
    urls
  end
  
  def transcoded_url
    self.asset ? "http://s3.amazonaws.com/#{self.asset.bucket_name}/assets/#{self.id}/transcoded/#{self.id}.mp4" : nil
  end
  
  def current_state
    if self.complete?
      state
    elsif zc_state
      "#{zencoder_status[0]} [#{zencoder_status[1]}%]"
    else
      state
    end
  end
  
  def dimensions
    (width && width > 0) ? "#{width} x #{height}" : "Unknown"
  end
  
  def duration_in_words
    if duration && duration > 0
      secs = duration / 1000
      mins = secs / 60
      rm_secs = secs % 60
      str_secs = rm_secs < 10 ? "0#{rm_secs}" : rm_secs.to_s
      "#{mins}:#{str_secs}"
    else
      "Unknown"
    end
  end
  
  def queue_upload_to_s3
    if self.pending?
     # ActiveQueue::Job.new(:val => {:video_id => self.id},:job_klass => "Jobs::VideoUploadJob",:adapter => 'insta').enqueue
     self.upload_to_s3
    end
    send_later(:upload_to_s3) #if self.local_asset_updated_at_changed?
  end
  
  def upload_to_s3
    self.upload! if self.uploading?
    self.asset = self.local_asset#.to_file
    # self.save!
    self.uploaded! unless self.uploaded?
    send_to_zencoder
    # ActiveQueue::Job.new(:val => {:video_id => self.id},:job_klass => "Jobs::VideoProcessJob",:adapter => 'resque').enqueue
  end
  
  def zencoder_status
    zc_current_event = "Finished"
    zc_progress = "100"
    
    if zc_state == "finished"
      zencoder_job_details
      self.complete!
    else
      zc_status = get_zencoder_status
      self.complete! if zc_status.body["state"] == "finished"
      self.update_attribute("zc_state",zc_status.body["state"]) if (zc_status.body["state"] != self.zc_state)
      zc_current_event = zc_status.body["current_event"] if zc_status.body["current_event"]
      zc_progress = zc_status.body["progress"] if zc_status.body["progress"]
    end
    [zc_current_event,zc_progress]
  end
  
  def zencoder_job_details
    zc_job_details = Zencoder::Job.details(self.zc_job_id, :api_key => ZENCODER_API_KEY) 
    if zc_job_details.body || zc_job_details.body["job"]["input_media_file"]["state"]
      duration = zc_job_details.body["job"]["input_media_file"]["duration_in_ms"]
      width = zc_job_details.body["job"]["input_media_file"]["width"]
      height = zc_job_details.body["job"]["input_media_file"]["height"]
      self.update_attributes(
        :duration => duration,
        :width => width,
        :height => height)
    end
  end
  
  def send_to_zencoder
    if !(complete? || transcoding? || uploading?)
      self.transcode!
      zc_job = zencoder_create_job
      
      job_id = zc_job.body["id"]
      output_file_id = zc_job.body["outputs"].first["id"]
    
      self.update_attributes(:zc_job_id => job_id, :zc_state => "sent", :zc_output_file_id => output_file_id)
    end
  end
  
  
  private
  

  def get_zencoder_status
    zc_status = Zencoder::Output.progress(self.zc_output_file_id, :api_key => ZENCODER_API_KEY) 
    self.update_attribute("zc_state",zc_status.body["state"]) if zc_status.body["state"] != self.zc_state
    zc_status
  end
  
  def zencoder_create_job
    Zencoder::Job.create({
      :api_key => ZENCODER_API_KEY,
      :input => "s3://#{self.asset.bucket_name}/#{self.asset.path}",                                 
      :outputs => [
        {
          :thumbnails => {:number => self.thumbnail_count, :base_url => "s3://#{self.asset.bucket_name}/assets/#{self.id}/thumbnails/", :prefix => "thumb"},
          :label => "web", :height => "320", :url => "s3://#{self.asset.bucket_name}/assets/#{self.id}/transcoded/#{self.id}.mp4",
          :public => 1
        }
      ]})
  end
  
  
  def init_s3_connection
    begin
      require 'aws/s3'
    rescue LoadError => e
      e.message << " (You may need to install the aws-s3 gem)"
      raise e
    end

    @s3_credentials = parse_credentials(S3_CREDENTIALS)
    AWS::S3::Base.establish_connection!(
    :access_key_id => @s3_credentials[:access_key_id],
    :secret_access_key => @s3_credentials[:secret_access_key]
    )
  end
  
  def parse_credentials(creds)
    creds = find_credentials(creds).stringify_keys
    (creds[Rails.env] || creds).symbolize_keys
  end
  
  def find_credentials(creds)
    case creds
    when File
      YAML::load(ERB.new(File.read(creds.path)).result)
    when String, Pathname
      YAML::load(ERB.new(File.read(creds)).result)
    when Hash
      creds
    else
      raise ArgumentError, "Credentials are not a path, file, or hash."
    end
  end
  
  def delete_zc_generated_files
    init_s3_connection
    
    @queued_for_delete = [
      "assets/#{self.id}/transcoded/#{self.id}.mp4",
      "assets/#{self.id}/thumbnails/thumb_0000.png",
      "assets/#{self.id}/thumbnails/thumb_0001.png",
      "assets/#{self.id}/thumbnails/thumb_0002.png",
      "assets/#{self.id}/thumbnails/thumb_0003.png",
      "assets/#{self.id}/thumbnails/thumb_0004.png"]
      
    @queued_for_delete.each do |path|
      begin
        AWS::S3::S3Object.delete(path, S3_BUCKET)
      rescue AWS::S3::ResponseError
        # Ignore this.
      end
    end
    @queued_for_delete = []
  end
  
  
end
