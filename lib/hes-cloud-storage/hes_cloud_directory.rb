module HesCloudStorage
  # Class structure to make it easy to view folders from HES Cloud
  class HesCloudDirectory
    include HesCloudUrl

    def initialize(folder_path)
      @app_key = HesCloudStorage.configuration[:app_key]
      @app_folder = HesCloudStorage.configuration[:app_folder]
      @folder_path = folder_path
      @base_path = cloud_url(true)
    end

    def files
      RestClient.get("#{@base_path}/applications/#{@app_key}/hes_files?folder=#{@folder_path}") do |response, request, content|
        hes_files = JSON.parse(response).collect{|x| HesCloudFile.new(x["file"]["url"].split('/').last, :folder_path => @folder_path) rescue nil}
        return hes_files
      end
    end
  end
end