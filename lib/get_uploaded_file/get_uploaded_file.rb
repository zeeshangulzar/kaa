module GetUploadedFile

  def self.included(base)
    base.send(:before_filter, :get_uploaded_image, :if => lambda{params.to_s.include?("/tmp/uploaded_files") && params[:action] != "crop"})
  end

  def get_uploaded_image
    if params && params.is_a?(Hash)
      iterate_hash(params)
    end
  end

  def iterate_hash(hash)
    hash.each_pair do |key, value|
      if value.is_a?(Hash)
        iterate_hash(value)
      elsif value.is_a?(Array)
        iterate_array(value)
      elsif value.is_a?(String) && value.include?("/tmp/uploaded_files")
        hash[key] = get_uploaded_file(value)
      end
    end
  end

  def iterate_array(array)
    array.each_with_index do |value, index|
      if value.is_a?(Hash)
        iterate_hash(value)
      elsif value.is_a?(Array)
        iterate_array(value)
      elsif value.is_a?(String) && value.include?("/tmp/uploaded_files")
        array[index] = get_uploaded_file(value)
      end
    end
  end

  def get_uploaded_file(path)
    tempfile = Tempfile.new(path.split("/").last)
    tempfile.set_encoding(Encoding::BINARY) if tempfile.respond_to?(:set_encoding)
    FileUtils.copy_file("#{Rails.root}/public#{path}", tempfile.path)
    ActionDispatch::Http::UploadedFile.new({:filename => path.split("/").last, :tempfile => tempfile})
  end
end