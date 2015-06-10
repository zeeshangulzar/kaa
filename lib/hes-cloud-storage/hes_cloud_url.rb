module HesCloudStorage
	module HesCloudUrl
		def cloud_url(with_login_credentials = false)
      		@cloud_url ||= "#{HesCloudStorage::SUBDOMAIN}#{HesCloudFile.cdn_sequence rescue 1}.#{HesCloudStorage.configuration[:domain]}"
      		"#{HesCloudStorage.configuration[:use_ssl] ? 'https' : 'http'}://#{ "#{HesCloudStorage::USER}:#{HesCloudStorage::PASSWORD}@" if with_login_credentials}#{@cloud_url}"
		end
	end
end