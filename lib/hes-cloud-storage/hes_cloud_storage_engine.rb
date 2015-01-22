module HesCloudStorage
  # The storage engine that saves files to the HES Cloud application
  class HesCloudStorageEngine < CarrierWave::Storage::Abstract

    # Move the file to the uploader's store path.
    #
    # @param [CarrierWave::SanitizedFile] file the file to store
    #
    # @return [CarrierWave::SanitizedFile] a sanitized file
    def store!(file)
      f = HesCloudStorage::HesCloudStorageEngine::File.new(uploader, self, uploader.store_path)
      f.store(file)
      f
    end

    # Retrieve the file from its store path
    #
    # @param [String] identifier the filename of the file
    # @return [CarrierWave::SanitizedFile] a sanitized file
    def retrieve!(identifier)
      HesCloudStorage::HesCloudStorageEngine::File.new(uploader, self, ::File.basename(uploader.store_path(identifier), uploader.root))
    end

    # Class to wrap around HESCloud file so that it behaves closely to SanitizedFile
    class File

      # Current local path to file
      #
      # @return [String] a path to file
      attr_reader :path

      # Return extension of file
      #
      # @return [String] extension of file
      def extension
        path.split('.').last
      end

      def content_type
        file.content_type
      end

      # Initializes HESCloud::File
      #
      # @param [CarrierWave::Uploader::Base] uploader
      # @param [HesCloudStorage::HesCloud] base hes cloud storage engine
      # @param [String] path to file
      def initialize(uploader, base, path)
        @uploader, @base, @path = uploader, base, "#{path}"
      end

      # Read content of file from service
      #
      # @return [String] contents of file
      def read
        file.read
      end

      # Return size of file body
      #
      # @return [Integer] size of file body
      def size
        file.size
      end

      # Returns the url of the HES Cloud file
      # @return [String] url of HES Cloud file
      def url(options = {})
        file.path
      end

      # Returns the filename of the HES Cloud file
      # @return [String] name of file in HES Cloud file
      def filename(options = {})

        if file_url = url(options)
          file_url.gsub(/.*\/(.*?$)/, '\1')
        end
      end


      # Check if the file exists on the remote service
      #
      # @return [Boolean] true if file exists or false
      def exists?
        file.exists?
      end

      # Write file to HES Cloud service
      #
      # @return [Boolean] true on success or raises error
      def store(new_file)
        @file = HesCloudStorage::HesCloudFile.new(new_file.to_file, :folder_path => @uploader.store_dir == "uploads" ? nil : @uploader.store_dir, :parent_model => @uploader.model.class)
        @file.save
        @path = @file.path

        true
      end

      # Remove the file from HES Cloud
      #
      # return [Boolean] true for success or raises error
      def delete
        @file = nil
        # file.delete
      end

      private

      # Returns the HesCloudFile
      # @return [HesCloudFile] object representing file in HES Cloud
      def file
        @file ||= HesCloudStorage::HesCloudFile.new(self.path, :parent_model => @uploader.model.class, :folder_path => @uploader.store_dir == "uploads" ? nil : @uploader.store_dir)
      end
    end
  end
end
