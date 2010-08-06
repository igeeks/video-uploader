class AddZencoderJobIdToVideos < ActiveRecord::Migration
  def self.up
    add_column :videos, :zc_job_id, :string
    add_column :videos, :zc_state, :string
  end

  def self.down
    remove_column :videos, :zc_state
    remove_column :videos, :zc_job_id
  end
end
