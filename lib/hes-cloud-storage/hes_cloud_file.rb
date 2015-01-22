module HesCloudStorage
  # Class structure to make it easy to save and delete files from HES Cloud
  class HesCloudFile
      
    include HesCloudStorage::HesCloudUrl

    cattr_accessor :current_cdn_sequence

    def self.cdn_sequence
      @@current_cdn_sequence ||= 1  
      sequence = @@current_cdn_sequence
      @@current_cdn_sequence += 1
      @@current_cdn_sequence = 1 if @@current_cdn_sequence > HesCloudStorage::MAX_CDN_SEQUENCE

      sequence
    end

    # Current local path to file
    #
    # @return [String] a path to file
    attr_reader :path

    # Initializes HESCloud::File
    #
    # @param [String, File] file_or_identifier used to create new file on Hes Cloud or to retrieve file from Hes Cloud
    # @param [Hash] options for HesCloudFile, currently just allows parent_model to be specified
    def initialize(file_or_identifier, options = {})
      @app_key = HesCloudStorage.configuration[:app_key]
      @app_folder = HesCloudStorage.configuration[:app_folder]
      @base_path = cloud_url(true)

      @id = nil
      @parent_model = options[:parent_model] == NilClass ? "" : options[:parent_model].to_s
      @folder_path = options[:folder_path] ? options[:folder_path].chomp("/") : (!@parent_model.empty? ? @parent_model.to_s.underscore.pluralize : "files")

      unless file_or_identifier.is_a?(String)
        @file = file_or_identifier
        @path = file_or_identifier.path
      else
        @path = "#{cloud_url}/#{@app_folder}/#{@folder_path}/#{file_or_identifier}"
      end
    end

    # Alias for path
    # @return [String] url (or path) of HES Cloud image
    def url
      @path
    end

    # Return extension of file
    #
    # @return [String] extension of file
    def extension
      File.extname(self.path)
    end

    # Returns the name of the file minus the extension
    # @return [String] name of file minus extension
    def slug
      @slug ||= File.basename(self.path, self.extension)
    end

    # Gets the content type of the file
    # @return [String] type of file
    def content_type
      @content_type ||= ::MIME::Types.type_for(filename).first.to_s
    end

    # Read content of file from service
    #
    # @return [String] contents of file
    def read
      contents = ""
      File.open(file.path).each {|line|
        contents << line
      }
      contents
    end

    # Return size of file body
    #
    # @return [Integer] size of file body
    def size
      File.size(file.path)
    end

    # Returns the id of the hes cloud file
    # @return [Integer] id of hes cloud file
    def id
      @id
    end

    # Returns the filename only of the HES Cloud file
    # @return [String] filename of HES Cloud File
    def filename
      File.basename(self.path)
    end

    # Remove the file from HES Cloud
    #
    # return [Boolean] true for success or raises error
    def delete
      RestClient.delete("#{@base_path}/applications/#{@app_key}/hes_files/destroy?filepath=#{@path}", {}) do |response, request, content|
        raise HesCloudFileError.new("Cannot delete: HES Cloud File does not exist <#{self.inspect}>") if response.code == 404
        return true
      end
    end

    # Check if the file exists on the remote service
    #
    # @return [Boolean] true if file exists or false
    def exists?
      RestClient.get("#{@base_path}/applications/#{@app_key}/hes_files/exists?filepath=#{@path}", {}) do |response, request, content|
        return response.code != 404
      end
    end

    # Write file to HES Cloud service
    #
    # @return [Boolean] true on success or raises error
    def save
      response = RestClient.post("#{@base_path}/applications/#{@app_key}/hes_files", {:hes_file => {:slug => self.slug, :file_type => self.content_type, :parent_model => @parent_model, :file => @file, :folder_path => @folder_path}})

      hes_cloud_file = JSON.parse(response)

      @path = hes_cloud_file["file"]["url"]
      @path.gsub!('http', 'https') if HesCloudStorage.configuration[:use_ssl]
      @id = hes_cloud_file["id"]
      @content_type = hes_cloud_file["content_type"]
      @slug = hes_cloud_file["slug"]
      @parent_model = hes_cloud_file["parent_model"]
      @folder_path = hes_cloud_file["folder_path"]
      @file = nil

      true
    # rescue
    #   raise HesCloudFileError.new("Saving file to HES Cloud was not successful <#{self.inspect}>")
    end

    private

    # Gets the file that has already been set or retrieves it from the HES Cloud
    # @return [File] file from HES Cloud
    def file
      return @file if @file

      puts "\nGrabbing file<#{@path}> from HES Cloud\n" if Rails.env.test? # Leave here to make sure we aren't grabbing file from Cloud unless necessary

      require "open-uri"
      remote_url = @path.gsub("https", "http") # Don't need ssl to grab between servers
      remote_data = open(remote_url).read
      tmp_file = open(Rails.root.join("tmp", self.filename), "w")
      tmp_file.write(remote_data)
      tmp_file.close

      @file ||= tmp_file
    rescue => detail
      Rails.logger.info detail.backtrace.join("\n")
      raise HesCloudFileError.new("Cannot retrieve file for HES Cloud <#{self.inspect}>") if Rails.env.production?
    end

  end
end
