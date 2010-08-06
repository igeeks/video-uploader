class AddDurationAndDimensionsToVideos < ActiveRecord::Migration
  def self.up
    add_column :videos, :duration, :integer
    add_column :videos, :height, :integer
    add_column :videos, :width, :integer
  end

  def self.down
    remove_column :videos, :width
    remove_column :videos, :height
    remove_column :videos, :duration
  end
end
