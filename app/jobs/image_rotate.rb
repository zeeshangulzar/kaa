class ImageRotate
  @queue = :image_processing
  DIRNAME = Rails.root.join("public/tmp/uploaded_files")

  def self.perform(job_key, options = {})
    if options['image_type'].nil?
      raise "invalid image type"
    end
    ActiveRecord::Base.verify_active_connections!
    if options['image_type'] == 'local'
      new_img = Magick::Image.read(options['image_path']).first rescue nil
      if new_img
        new_img.rotate!(options['rotation'])
        new_img.write(options['new_image_path'])
      else
        raise "unable to save local image"
      end
    elsif options['image_type'] == 'object'
      obj = options['object_type'].constantize.find(options['object_id']) rescue nil
      raise "invalid object or image key" unless obj && obj.respond_to?(options['image_key'])
      img = obj.send(options['image_key'])
      raise "no object file" if img.file.nil?
      new_filename = "#{DIRNAME}/#{img.file.filename}"
      new_img = Magick::Image.read(img.url).first
      new_img.rotate!(options['rotation'])
      new_img.write(new_filename)
      obj.send("#{options['image_key']}=", new_filename)
      obj.save!
    end
  end
end
