class AddZcOutputIdToVideos < ActiveRecord::Migration
  def self.up
    add_column :videos, :zc_output_file_id, :string
  end

  def self.down
    remove_column :videos, :zc_output_file_id
  end
end
