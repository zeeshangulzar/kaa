class GalleryImagesController < ApplicationController
  GalleryRailsRoute = 'gallery_images'
  GalleryApacheDir = 'galleries'
  GalleryRootDir = File.expand_path(Rails.root.join('public',GalleryApacheDir))
  IgnoredFiles = ['.hidden-files','.deleted-files']
  DirStub = {:name=>nil,:files=>[],:hidden_files=>[],:deleted_files=>[],:folders=>[]}

  # all of this is master only, mostly because we're allowing the creation of directories on the server and writing files (i.e. upload a new file named ../../../usr/bin/httpd and you now own the server)
  # any GETs for individual images will be served by Apache as static files
  authorize :all, :master

  skip_before_filter :get_uploaded_image
  before_filter :set_path_and_file

  
  def set_path_and_file
    # ignore params file and path; just use 

    # path might be program-logos/h4h.png
    # path could be ../../../../../../../../../usr/bin/httpd   (welcome to 1998)
    # your server could be compromised if you trust the path and write the file
    # so expand it (turn all the dots and things into their actual path) and make sure the result is a child of the expected directory
    # otherwise you could get owned

    requested_path = request.path.gsub(/^\/#{GalleryRailsRoute}\//,'').gsub(/^\/#{GalleryRailsRoute}/,'')
    requested_path_on_disk = Pathname.new(GalleryRootDir).join(requested_path).to_s
    ok = File.expand_path(requested_path_on_disk).start_with?(GalleryRootDir)
    # Rails.logger.info "asked for: #{File.expand_path(requested_path_on_disk)}\nGalleryRootDir: #{GalleryRootDir}\nok?: #{ok}"

    if ok
      @path = requested_path_on_disk
    else
      head :forbidden
    end
  end

  # GET /galleries
  # example response for root folder
  # {"name": "galleries", {"folders": [{"name": "billboards"}, {"name": "billboards-responsive", "name": "program-logos"]}}
  # GET /galleries/path/to/child
  # example response for a child folder -- folders and files, recursive
  # {"name": "billboards", 
  #    {"files": ["walktober.png","walktober2.png"], 
  #      "hidden_files": ["abc-company.png"], 
  #      "deleted_files": ["asdfasdf.png"], 
  #      "folders": [
  #        {"name": "last-year", 
  #         "files": ["walk.png","run.png"], 
  #         "hidden_files": [], 
  #         "deleted_files": []
  #       }
  #    }
  # }
  def index
    # if requesting the contents of the root, return folder names only
    # if requesting the contents of any subfolder, return folders and files
    if File.directory?(@path)
      render :json => get_dir_contents(@path)
    else
      if File.exists?(@path)
        render :text=>"#{request.path} is a file, not a directory.  Can not list contents.", :status => 400
      else
        render :text=>"#{request.path} does not exist.  Can not list contents.", :status => 400
      end
    end
  end

  def get_dir_contents(path,recursive=path!=GalleryRootDir.to_s)
    #Rails.logger.info "Getting contents of: #{path}"

    slashes_count = path.split('/').size
    hash = Marshal.load(Marshal.dump(DirStub))
    hash[:name] = File.basename(path)
    glob = "#{path}/*"
    contents = Dir[glob]
    #Rails.logger.info "contents: #{contents.inspect}"

    hidden_file = Pathname.new(path).join('.hidden-files')
    hidden_file_names = File.exists?(hidden_file) ? File.read(hidden_file).split("\n") : []
    deleted_file = Pathname.new(path).join('.deleted-files')
    deleted_file_names = File.exists?(deleted_file) ? File.read(deleted_file).split("\n") : []

    contents.each do |item|
      short_name = File.basename(item)
      if File.directory?(item)
        if recursive
          hash[:folders] << get_dir_contents(item)
        else
          hash[:folders] << {:name => File.basename(item)}
        end
      elsif item.split('/').size-1 == slashes_count
        if hidden_file_names.include?(short_name)
          hash[:hidden_files] << file_path_to_hash(item)
        elsif deleted_file_names.include?(short_name)
          hash[:deleted_files] << file_path_to_hash(item)
        else
          hash[:files] << file_path_to_hash(item) 
        end
      end
    end
    hash
  end
  private :get_dir_contents

  def file_path_to_hash(path)
    {:name=>File.basename(path),:http_path=>"/#{GalleryApacheDir}#{path.gsub(/^#{GalleryRootDir}/,'')}",:edit_path=>"/#{GalleryRailsRoute}#{path.gsub(/^#{GalleryRootDir}/,'')}"}
  end
  private :file_path_to_hash

  # POST /galleries/path/to/the/file.png
  # mkdir_p if necessary (i.e. make the folder structure)
  # write the uploaded file to disk
  # sanitize its file name 
  # add it to or remove it from .hidden-images if necessary
  def create
    # turn blabla.png into blabla_versioned_yyyymmddhhmmss.png
    # turn blabla into blabla_versioned_yyyymmddhhmmss

    # some REST clients don't let you specify the name of the parameter, so just dig for it
    # file = params.values.detect{|v|v.is_a?(IO) || v.is_a?(ActionDispatch::Http::UploadedFile)}
    file = get_uploaded_files.first

    timestamp = "_versioned_#{Time.now.utc.strftime('%Y%m%d%H%M%S')}"
    # requested_file_name = File.basename(@path)
    requested_file_name = file.original_filename
    if requested_file_name =~ /\./
      pieces = requested_file_name.split('.')
      pieces[-2] = "#{pieces[-2]}#{timestamp}"
      actual_file_name = pieces.join('.')
    else
      actual_file_name = "#{requested_file_name}#{timestamp}"
    end
    FileUtils.mkdir_p(File.dirname(@path))
    # actual_file_full_path = Pathname.new(File.dirname(@path)).join(actual_file_name).to_s
    actual_file_full_path = File.join(@path, actual_file_name)
    File.open(actual_file_full_path,"wb") {|f| f.write(file.read)}

    render :json=>file_path_to_hash(actual_file_full_path)
  end

  # PUT /galleries/path/to/the/file.png
  # :id is original file name
  # overwite it with the uploaded file
  # add it to or remove it from .hidden-images if necessary
  def update
    if File.exists?(@path)
      # some REST clients don't let you specify the name of the parameter, so just dig for it
      file = params.values.detect{|v|v.is_a?(IO) || v.is_a?(ActionDispatch::Http::UploadedFile)}
      if file
        File.open(@path,"wb") {|f| f.write(file.read)}
      end

      if params[:hidden]
        hidden_file = Pathname.new(File.dirname(@path)).join('.hidden-files')
        hidden_file_names = File.exists?(hidden_file) ? File.read(hidden_file).split("\n") : []
        short_name = File.basename(@path)
        if params[:hidden] == 'true'
          unless hidden_file_names.include?(short_name)
            hidden_file_names << short_name
            File.open(hidden_file,'wb') {|f| f.puts hidden_file_names.join("\n") }
          end
        elsif params[:hidden] == 'false'
          if hidden_file_names.include?(short_name)
            hidden_file_names.delete(short_name)
            File.open(hidden_file,'wb') {|f| f.puts hidden_file_names.join("\n") }
          end
        end
      end

      render :json=>file_path_to_hash(@path)
    else
      head 404
    end
  end

  # DELETE /galleries/path/to/the/file.png
  # do not delete from disk
  # just write the file name to .deleted-files
  def destroy
    if File.exists?(@path)
      deleted_file = Pathname.new(File.dirname(@path)).join('.deleted-files')
      deleted_file_names = File.exists?(deleted_file) ? File.read(deleted_file).split("\n") : []
      short_name = File.basename(@path)
      unless params[:undelete] == 'true'
        unless deleted_file_names.include?(short_name)
          deleted_file_names << short_name
          File.open(deleted_file,'wb') {|f| f.puts deleted_file_names.join("\n") }
        end
      else
        if deleted_file_names.include?(short_name)
          deleted_file_names.delete(short_name)
          File.open(deleted_file,'wb') {|f| f.puts deleted_file_names.join("\n") }
        end
      end
      head :ok
    else
      head 404
    end
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
