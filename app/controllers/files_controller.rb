class FilesController < ApplicationController
  respond_to :html
  authorize :upload, :crop, :rotate, :public
  skip_before_filter :get_uploaded_image

  DIRNAME = Rails.root.join("public/tmp/uploaded_files")

  # Uploads a photo and returns a temporary file path that can be used to assign to a model instance.
  # File can be uploaded on any parameters as long file corresponds to ActionDispatch::Http::UploadedFile.
  #
  # @url [POST] /files/upload
  # @authorize Public
  # @return [Hash] A list of all the files that were just uploaded with timestamps
  #
  # [URL] /files/upload [POST]
  #  [201 CREATED] Successfully uploaded file
  #   # Example response
  #   {
  #     "files": ["/tmp/uploaded-file-123123.jpg", "/tmp/uplaoded-file-235scbxads.jpg"]
  #   }
  def upload
    require 'RMagick'
    uploaded_files = []
    get_uploaded_files.each do |uploaded_file|
      name = uploaded_file.original_filename
      name = "#{params[:_t] || Time.now.to_i}-#{name}"

      unless FileTest::directory?(DIRNAME)
        Dir::mkdir(Rails.root.join("public")) unless File.exists?(Rails.root.join("public"))
        Dir::mkdir(Rails.root.join("public/tmp")) unless File.exists?(Rails.root.join("public/tmp"))
        Dir::mkdir(DIRNAME)
      end

      path = File.join(DIRNAME, name)


      
      uploaded_files << {:url => "/#{path}".split('public').last, :name => name}
      File.open(path, "wb") { |f| f.write(uploaded_file.read) }

      begin
        tn_img = Magick::Image.read(path).first
        tn_img = tn_img.resize_to_fit(50, 50)

        tn_path = File.join(DIRNAME, "thumbnail-#{params[:_t]}-#{name}")
        tn_img.write(tn_path)
        
        uploaded_files.last[:thumbnail_url] = "/#{tn_path}".split('public').last

        if params[:resize_to_fit]
          width, height = params[:resize_to_fit].split(',').collect{|x| x.to_i}
          img = Magick::Image.read(path).first
          if img.rows > height || img.columns > width
            img = img.resize_to_fit(width, height)
            img.write(path)
          end
        end

        if params[:resize_to_fill]
          img = Magick::Image.read(path).first
          img = img.resize_to_fill(*params[:resize_to_fit].split(',').collect{|x| x.to_i})
          img.write(path)
        end

        if params[:poster_canvas]
          background_img =  Magick::Image.new 1920,1080
          background_img = background_img.color_floodfill(0,0,"#4A7628")

          img = Magick::Image.read(path).first
          # img.background_color = "blue"
          # img = img.extent(1920, 1080)
          # img.gravity = Magick::CenterGravity
          background_img.composite!(img, Magick::CenterGravity, Magick::OverCompositeOp)
          # convert img gravity center background white extent 1920x1080
          # img.write(path)
          background_img.write(path)
        end
      rescue Exception => e # stackoverflow said they'd stab me if i used this. so if i don't make it in one day, you can find me at st. mary's trauma center
        # Do nothing, file is not an image so thumbnail does not need to be made
      end
    end

    render :json => {:files => uploaded_files}, :status => 201, :content_type => "text/html"
  end

  # Uploads a photo and returns a temporary file path that can be used to assign to a model instance.
  # File can be uploaded on any parameters as long file corresponds to ActionDispatch::Http::UploadedFile.
  #
  # @url [POST] /files/upload
  # @authorize Public
  # @param [String] image Path to the image, must be on server already
  # @param [Hash] crop The dimensions of the cropped image
  # @param [Integer] x Crop: The x position to start to cropping
  # @param [Integer] y Crop: The y position to start to cropping
  # @param [Integer] w Crop: The width of the cropping
  # @param [Integer] h Crop: The height of the cropping
  # @return [Hash] The new file path, a thumbnail file path, and the new timestamped name of the image
  #
  # [URL] /files/upload [POST]
  #  [20@ ACCEPTED] Successfully cropped file with thumbnail image path with image urls timestamped
  #   # Example response
  #   {
  #     "url": "/tmp/uploaded-file-23545.jpg",
  #     "thumbnail_url": "tmp/thumb/uploaded-file-23545.jpg",
  #     "name": "uploaded-file123123-23545.jpg"
  #   }
  def crop
    return HESResponder("Invalid image.", "ERROR") unless params[:image]
    require 'RMagick'
    img_path = Dir["#{DIRNAME}/#{params[:image].split('/').last}"].first
    return HESResponder("Invalid image.", "ERROR") unless img_path
    name = img_path.split('/').last
    ext_type = img_path.split('.').last
    new_name = name.gsub(name.split('-').first, Time.now.to_i.to_s).gsub(ext_type, 'png')
    new_img_path = img_path.gsub(name, new_name);

    tn_path = File.join(DIRNAME, "thumbnail-#{new_name}")
    blur_path = File.join(DIRNAME, "blur_#{new_name}")
    if params[:type].nil? || params[:type] == 'rect' then
      crop_to_rect(img_path, params[:crop][:x], params[:crop][:y], params[:crop][:w], params[:crop][:h], new_img_path, tn_path, blur_path)
    else 
      crop_to_circle(img_path, new_img_path, params[:crop][:x], params[:crop][:y], params[:crop][:w], params[:crop][:h], tn_path)
    end
    render :json => {:url => "/#{new_img_path}".split('public').last, :thumbnail_url => "/#{tn_path}".split('public').last, :blur_url => "/#{blur_path}".split('public').last, :name => new_name}, :status => 202
  end

  def crop_to_circle(filename, out_filename, x = 0, y = 0, w = 0, h = 0, thumb_filename = nil)
    require 'RMagick'

    img_path = filename
    img = Magick::Image.read(img_path).first
    w = [w, img.columns-x].min
    h = [h, img.rows-y].min
    w = [w,h].min
    h = w
    img = img.crop(x,y,w,h)

    circle = Magick::Image.new w,h 
    gc = Magick::Draw.new
    gc.fill 'black'
    gc.circle w/2, w/2, w/2, 1
    gc.draw circle

    mask = circle.blur_image(0,1).negate

    mask.matte = false
    img.matte = true
    img.composite!(mask, Magick::CenterGravity, Magick::CopyOpacityCompositeOp)

    name = img_path.split('/').last
    new_name = name.gsub(name.split('-').first, Time.now.to_i.to_s)
    img_path = img_path.gsub(name, new_name)

    if !thumb_filename.nil?
      tn_path = File.join(thumb_filename)
    else 
      tn_path = File.join(DIRNAME, "thumbnail-#{out_filename}")
    end

    tn_img = img.resize_to_fit(50, 50)
    tn_img.write(tn_path)
    img.write(out_filename)
  end

  def crop_to_rect(filename, x, y, w, h, out_filename, thumb_filename=nil, blur_filename=nil)
    img_path = filename
    img = Magick::Image.read(img_path).first
    # w = [w, img.columns-x].min
    # h = [h, img.rows-y].min
    # w = [w,h].min
    # h = w
    img = img.crop(x,y,w,h)

    name = img_path.split('/').last
    new_name = name.gsub(name.split('-').first, Time.now.to_i.to_s)
    img_path = img_path.gsub(name, new_name)

    if !thumb_filename.nil?
      tn_path = File.join(thumb_filename)
    else 
      tn_path = File.join(DIRNAME, "thumbnail-#{out_filename}")
    end

    if !blur_filename.nil?
      blur_path = File.join(blur_filename)
    else
      tn_path = File.join(DIRNAME, "blur-#{out_filename}")
    end

    ratio = w/h
    tn_h = 50
    tn_w = tn_h * ratio

    tn_img = img.resize_to_fit(tn_w, tn_h)
    tn_img.write(tn_path)

    blur_img = img.blur_image(0, 25.0)
    blur_img.write(blur_path)

    img.write(out_filename)
  end

  def rotate
    unless params[:object_id].nil? || params[:object_type].nil? || params[:image_key].nil? || params[:rotation].nil?
      obj = params[:object_type].singularize.camelcase.constantize.find(params[:object_id]) rescue nil
      if !obj
        return HESResponder("Object", "NOT_FOUND")
      end
    else
      return HESResponder("Must pass object_type, object_id, image_key and rotation.", "ERROR")
    end
    unless (obj.respond_to?("user_id") && @current_user && obj.user_id == @current_user.id) || @current_user.master?
      return HESResponder("Access denied.", "DENIED")
    end
    if !obj.respond_to?(params[:image_key])
      return HESResponder("Invalid image_type", "ERROR")
    end
    img = obj.send(params[:image_key])
    if img.file.nil?
      return HESResponder("Object has no associated file.", "ERROR")
    end
    if !params[:rotation].to_s.is_i?
      return HESResponder("Invalid rotation.", "ERROR")
    end
    new_filename = "#{DIRNAME}/#{img.file.filename}"
    new_img = Magick::Image.read(img.url).first
    new_img.rotate!(params[:rotation])
    new_img.write(new_filename)
    obj.send("#{params[:image_key]}=", new_filename)
    obj.save!
    response = {
      :data => {
        :url => obj.send(params[:image_key]).url
      },
      :meta => {
        :total_records => 1
      }
    }
    return HESResponder(response)
  end

  private

  def get_uploaded_files
    @uploaded_files = []
    iterate_params(params)

    @uploaded_files
  end

  def iterate_params(hash)
    hash.each_pair do |key, value|
      if value.is_a?(Hash)
        iterate_params(value)
      elsif value.is_a?(Array)
        iterate_array_param(value)
      elsif value.is_a?(ActionDispatch::Http::UploadedFile)
        @uploaded_files << value
      end
    end
  end

  def iterate_array_param(array)
    array.each_with_index do |value, index|
      if value.is_a?(Hash)
        iterate_params(value)
      elsif value.is_a?(Array)
        iterate_array_param(value)
      elsif value.is_a?(ActionDispatch::Http::UploadedFile)
        @uploaded_files << value
      end
    end
  end
end