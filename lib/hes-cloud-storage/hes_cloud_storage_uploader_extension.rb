module HesCloudStorage
  # Module that extends CarrierWave Uploader to better handle HES Cloud Storage
  module HesCloudStorageUploaderExtension
    # Adds a callback after a file is stored
    def self.included(base)
      base.send(:after, :store, :save_hes_cloud_filename)
      # base.send(:after, :remove, :remove_hes_cloud_filename)
    end

    # Need to resave model since it is saved before file is stored on HES Cloud server and filename will not be known until after file is saved
    def save_hes_cloud_filename(file)
      if self.send(:storage).is_a?(HesCloudStorage::HesCloudStorageEngine)
        self.model.update_column(self.mounted_as, self.file.filename) if self.model
      end
    end

    # Need to resave model since it is saved before file is stored on HES Cloud server and filename will not be known until after file is saved
    # def remove_hes_cloud_filename
    #   if self.send(:storage).is_a?(HesCloudStorage::HesCloudStorageEngine)
    #     self.model.update_column(self.mounted_as, nil) if self.model
    #   end
    # end
  end
end
