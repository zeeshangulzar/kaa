class MapsController < ApplicationController
  authorize :index, :show, :user
  authorize :create, :update, :destroy, :update_maps, :upload, :master

  before_filter :set_sandbox
  def set_sandbox
    @SB = use_sandbox? ? @promotion.maps : Map
  end
  private :set_sandbox

  def index
    return HESResponder(@SB.send(*record_status_scope('active')))
  end

  def show
    @SB = Map.active
    if @current_user.master?
      @SB = Map
    end
    map = @SB.find(params[:id]) rescue nil
    return HESResponder("Map", "NOT_FOUND") if map.nil? || (!@current_user.master? && !@promotion.maps.include?(map))
    HESCachedResponder(map.cache_key, map) do
      map.attach('routes', map.routes)
      map.attach('destinations', map.destinations)
      map
    end
  end

  def create
    map = nil
    Map.transaction do
      map = @SB.new(params[:map]) rescue nil
      return HESResponder(map.errors.full_messages, "ERROR") if !map.valid?
      map.save!
    end
    return HESResponder(map)
  end

  def update
    map = @SB.find(params[:id]) rescue nil
    return HESResponder("Map", "NOT_FOUND") if map.nil?
    Map.transaction do
      map.update_attributes(params[:map])
    end
    return HESResponder(map)
  end

  def destroy
    map = @SB.find(params[:id]) rescue nil
    return HESResponder("Map", "NOT_FOUND") if map.nil?
    Map.transaction do
      map.destroy
    end
    return HESResponder(map)
  end

  def update_maps
    if params[:map_ids].is_a?(Array)
      Map.transaction do
        @promotion.maps = []
        params[:map_ids].each{|map_id|
          map = Map.find(map_id) rescue nil
          return HESResponder("Map ID: #{map_id}", "NOT_FOUND") if map.nil?
          @promotion.maps << map
        }
      end
      return HESResponder(@promotion.maps)
    else
      return HESResponder("Bad request.", "ERROR")
    end
  end

  def upload
    require 'RMagick'
    map = Map.find(params[:map_id]) rescue nil
    return HESResponder("Map", "NOT_FOUND") if map.nil?
    if params[:image].is_a?(ActionDispatch::Http::UploadedFile)
      uploaded_file = params[:image]
  
      Dir::mkdir(Rails.root.join("public/galleries/maps")) unless File.exists?(Rails.root.join("public/galleries/maps"))
      Dir::mkdir(Rails.root.join("public/galleries/maps/#{map.id}")) unless File.exists?(Rails.root.join("public/galleries/maps/#{map.id}"))
      Dir::mkdir(Rails.root.join("public/galleries/maps/#{map.id}/originals")) unless File.exists?(Rails.root.join("public/galleries/maps/#{map.id}/originals"))


      map_root_path = Rails.root.join("public/galleries/maps/#{map.id}")
      upload_path = "#{map_root_path}/originals"
      filepath = "#{upload_path}/#{Time.now.to_i}-#{uploaded_file.original_filename.gsub(/[^0-9A-Z\.]/i, '_')}"
      web_map_path = "galleries/#{map.id}"

      File.open(filepath, "wb") { |f| f.write(uploaded_file.read) }

      img = Magick::Image.read(filepath).first rescue nil
      if img.nil?
        return HESResponder("Something went terribly wrong.", "ERROR")
      else

        scale_zoom = map.settings['scale_zoom'].to_i
        min_zoom = params[:min_zoom].nil? ? map.settings['min_zoom'].to_i : params[:min_zoom].to_i
        max_zoom = params[:max_zoom].nil? ? map.settings['max_zoom'].to_i : params[:max_zoom].to_i

        scale = 100
        max_zoom.downto(min_zoom).each{|i|
          next if i >= scale_zoom
          factor = 2 ** (scale_zoom - i)
          percent = (100.0/factor).to_f

          zoom_path = "#{map_root_path}/#{i}" 

          Dir::mkdir(zoom_path) unless File.exists?(zoom_path)

          command = "convert #{filepath} -resize #{percent}%  -crop #{map.settings['tile_size']}x#{map.settings['tile_size']} -set filename:tile \"%[fx:page.x/#{map.settings['tile_size']}]-%[fx:page.y/#{map.settings['tile_size']}]\" +repage +adjoin \"#{zoom_path}/%[filename:tile].png\""

Rails.logger.warn scale_zoom
Rails.logger.warn i
Rails.logger.warn factor
Rails.logger.warn command
result = `#{command}`



        }
        Map.transaction do
          map.image_dir = web_map_path
          map.settings['image_width'] = img.columns
          map.settings['image_height'] = img.rows
          map.save!
        end
        return HESResponder("You got here")
      end
    else
      return HESResponder("Baaad image", "ERROR")
    end
  end

end
