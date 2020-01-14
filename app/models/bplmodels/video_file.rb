module Bplmodels
  class VideoFile < Bplmodels::File

    has_many :next_video, :class_name => 'Bplmodels::VideoFile', :property => :is_preceding_video_of

    has_many :prev_video, :class_name => 'Bplmodels::VideoFile', :property => :is_following_video_of

    def is_video?
      true
    end

    def fedora_name
      'video_file'
    end
  end
end
