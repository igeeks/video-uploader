class AddThumbnailCountToVideos < ActiveRecord::Migration
  def self.up
    add_column :videos, :thumbnail_count, :integer
    add_column :videos, :selected_thumbnail, :integer
  end

  def self.down
    remove_column :videos, :selected_thumbnail
    remove_column :videos, :thumbnail_count
  end
end
