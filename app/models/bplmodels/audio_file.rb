module Bplmodels
  class AudioFile  < Bplmodels::File
    has_file_datastream 'productionMaster', :versionable=>true, :label=>'productionMaster datastream'

    has_many :next_audio, :class_name => "Bplmodels::AudioFile", :property=> :is_preceding_audio_of

    has_many :prev_audio, :class_name => "Bplmodels::AudioFile", :property=> :is_following_audio_of

    has_many :transcription, :class_name => "Bplmodels::File", :property=> :is_transcription_of

    def fedora_name
      'audio_file'
    end
  end
end