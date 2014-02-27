module Bplmodels
  class Finder

     def self.getFiles(pid)
       return_list = []
       Bplmodels::File.find_in_batches('is_file_of_ssim'=>"info:fedora/#{pid}") do |group|
         group.each { |solr_object|
           return_list << solr_object
         }
       end
       return return_list
     end

     def self.getImageFiles(pid)
       return_list = []
       Bplmodels::ImageFile.find_in_batches('is_image_of_ssim'=>"info:fedora/#{pid}") do |group|
         group.each { |solr_object|
           return_list << solr_object
         }
       end
       return return_list
     end

     def self.getAudioFiles(pid)
       return_list = []
       Bplmodels::AudioFile.find_in_batches('is_audio_of_ssim'=>"info:fedora/#{pid}") do |group|
         group.each { |solr_object|
           return_list << solr_object
         }
       end
       return return_list
     end

     def self.getDocumentFiles(pid)
       return_list = []
       Bplmodels::DocumentFile.find_in_batches('is_document_of_ssim'=>"info:fedora/#{pid}") do |group|
         group.each { |solr_object|
           return_list << solr_object
         }
       end
       return return_list
     end

     def self.getFirstImageFile(pid)
       Bplmodels::ImageFile.find_in_batches('is_image_of_ssim'=>"info:fedora/#{pid}", 'is_following_image_of_ssim'=>'') do |group|
         group.each { |solr_object|
           return solr_object
         }
       end
       return nil
     end

     def self.getFirstAudioFile(pid)
       Bplmodels::AudioFile.find_in_batches('is_audio_of_ssim'=>"info:fedora/#{pid}", 'is_following_audio_of_ssim'=>'') do |group|
         group.each { |solr_object|
           return solr_object
         }
       end
       return nil
     end

     def self.getFirstDocumentFile(pid)
       Bplmodels::DocumentFile.find_in_batches('is_document_of_ssim'=>"info:fedora/#{pid}", 'is_following_document_of_ssim'=>'') do |group|
         group.each { |solr_object|
           return solr_object
         }
       end
       return nil
     end

     def self.getNextImageFile(pid)
       Bplmodels::ImageFile.find_in_batches('is_following_image_of_ssim'=>"info:fedora/#{pid}") do |group|
         group.each { |solr_object|
           return solr_object
         }
       end
       return nil
     end

     def self.getNextAudioFile(pid)
       Bplmodels::AudioFile.find_in_batches('is_following_audio_of_ssim'=>"info:fedora/#{pid}") do |group|
         group.each { |solr_object|
           return solr_object
         }
       end
       return nil
     end

     def self.getNextDocumentFile(pid)
       Bplmodels::DocumentFile.find_in_batches('is_following_document_of_ssim'=>"info:fedora/#{pid}") do |group|
         group.each { |solr_object|
           return solr_object
         }
       end
       return nil
     end

     def self.getPrevImageFile(pid)
       Bplmodels::ImageFile.find_in_batches('is_preceding_image_of_ssim'=>"info:fedora/#{pid}") do |group|
         group.each { |solr_object|
           return solr_object
         }
       end
       return nil
     end

     def self.getPrevAudioFile(pid)
       Bplmodels::AudioFile.find_in_batches('is_preceding_audio_of_ssim'=>"info:fedora/#{pid}") do |group|
         group.each { |solr_object|
           return solr_object
         }
       end
       return nil
     end

     def self.getPrevDocumentFile(pid)
       Bplmodels::DocumentFile.find_in_batches('is_preceding_document_of_ssim'=>"info:fedora/#{pid}") do |group|
         group.each { |solr_object|
           return solr_object
         }
       end
       return nil
     end

  end
end