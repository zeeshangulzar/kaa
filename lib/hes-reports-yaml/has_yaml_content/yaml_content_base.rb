module HesReportsYaml
  module HasYamlContent
    class YamlContentBase

      extend ActiveModel::Naming if defined?(ActiveModel::Naming)
      include ActiveModel::Conversion if defined?(ActiveModel::Conversion)

      require 'ftools'

      DefaultPath = "default"
      CopyDefault = true

      attr_accessor :id, :updated_at, :order, :path, :attrs, :parent, :svn_path, :is_backup, :commit_on_save


      def self.add_default_path(model_name, default_path)
        @@default_paths ||= {}
        @@default_paths[model_name] = default_path
      end

      # Defines an attribute accessor for each of the keys passed in
      def self.attrs(*args)
        @attrs = args
        args.each { |a| attr_accessor a }
      end

      def [](attribute_name)
        self.send(attribute_name)
      end

      def []=(attribute_name, new_value)
        self.send("#{attribute_name}=", new_value)
      end

      def persisted?
        !id.nil?
      end

      def self.order_by(order)
        @order = order
      end

      def self.get_attrs
        return @attrs
      end

      def set_custom_path(path)
        @path = path
        @file = "#{path}/#{filename}"
      end

      def set_custom_svn_path(svn_path)
        @svn_path = svn_path
      end

      # Returns nil for any missing methods so if we add to
      # the default models, we don't have to go back and fix all
      # of the custom content that may have been created. (Nice!) <- agree
      def method_missing(symbol,*args)
        return nil
      end

      def is_default_path?
        return @file.include?(get_default_path)
      end

      def set_attribute_instances(vars,vals)
        vars.each { |k| self.instance_variable_set("@#{k.to_s}",vals[k]) }
      end
      private :set_attribute_instances

      def == a
        return @id == a.object_id
      end

      def filename
        "#{self.class.to_s.underscore}.yml"
      end

      def to_yaml_properties
        return ['@id','@updated_at'].concat(attributes.keys.collect { |a| "@#{a.to_s}"}.sort!)
      end

      def to_xml(options = {})
        options[:indent] ||= 2
        xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
        xml.instruct! unless options[:skip_instruct]
        xml.tag!(self.class.to_s.underscore) {
          attributes.each_pair do |k,v|
            xml.tag!(k.to_s, v, {:type => "string"})
          end
        }
      end

      # The new method takes a hash of parameters for the object
      def initialize(a={})
        @path = self.class.get_path(!a.nil? ? a[:path] : get_default_path)
        @svn_path = a[:svn_path]
        @file = "#{@path}/#{filename}" #returns default if custom path not supplied or doesn't exist
        @id = nil
        @image_version = 1
        @parent = a[:parent]
        @is_backup = false
        @commit_on_save = true
        (a || {}).each_pair{ |k,v| self.send("#{k}=",v) if attributes.include?(k.to_sym) }
      end

      def new_record?
        return id.nil?
      end

      def update_attributes(new_attributes={})
        new_attributes[@order] = new_attributes[@order].to_i unless new_attributes[@order].nil?

        @need_to_reorder_at = attributes[@order].to_i if new_attributes[@order].to_i != attributes[@order].to_i

        image = new_attributes.delete(:image)
        unless image.nil?
          save_image(image)
        end

        #this sets each of the instance variables found to the values supplied in the hash
        new_attributes.each_pair { |k,v| self.send("#{k}=",v) if attributes.include?(k.to_sym) }
        return save != false
      end

      def attributes
        a = {}
        self.class.get_attrs.each do |k|
          a[k] = self.send(k)
        end
        return a
      end

      def attributes=(new_attributes={})
        new_attributes[@order] = new_attributes[@order].to_i unless new_attributes[@order].nil?
        new_attributes.each_pair { |k,v| self.send("#{k}=",v) if attributes.include?(k.to_sym) }
        @image = new_attributes.delete(:image)
      end

      def attributes_equal?(compare_attributes)
        compare_attributes.each_pair do |k,v|
          return false if attributes[k.to_sym] != v && !attributes[k.to_sym].nil?
        end
        return true
      end

      def reorder_content(all, previous_order_value)
        new_order_value = attributes[@order].to_i

        if new_order_value > previous_order_value
          all.each_with_index do |content_instance, index|
            if content_instance.id != id && content_instance.attributes[@order] <= new_order_value && content_instance.attributes[@order] > previous_order_value
              content_instance[@order] = content_instance[@order] - 1
            end
          end
        elsif new_order_value < previous_order_value
          all.reverse.each_with_index do |content_instance, index|
            if content_instance.id != id && content_instance.attributes[@order] < previous_order_value && content_instance.attributes[@order] >= new_order_value
              content_instance[@order] = content_instance[@order] + 1
            end
          end
        end
        all
      end

      def updated_at
        @updated_at || Time.at(0) #time since epoch
      end

      # Save method writes any new or changed instance to the file.
      def save
        all = self.class.find_all(@path, @parent, @svn_path)

        @updated_at = Time.now.utc
        if new_record?
          @id = all.empty? ? 1 : (all.sort_by { |x| x.id }.reverse.collect { |x| x.id }.max + 1)

          #save an image if this object contains one
          unless @image.nil?
            save_image(@image)
          end

          all << self
          # write the record(s) to the file
          write_file(all)
          return self
        else

          all = reorder_content(all, @need_to_reorder_at) if @need_to_reorder_at

          all.each_with_index do |x,i|
            if x.id == self.id
              all[i] = self
              break
            end
          end
          # write the record(s) to the file
          write_file(all)
          return self
        end
        return false
      end

      def write_file(a)
        #create a backup in case anything goes wrong with the original file
        File.copy(@file, @file.gsub('.yml','-backup.yml')) if File.exists?(@file)

        #write the new contents to the file
        File.open(@file,'w') do |f|
          f.write a.to_yaml
        end
        #commit in svn if this is the default content file and we are in production
        commit
      end
      private :write_file

      def commit
        if @commit_on_save && is_default_path? && Rails.env.production?
          `svn add #{get_default_path}/#{filename}`
          `svn commit #{get_default_path}/#{filename} -m 'Committed #{self.class.name} content file'`
        elsif @commit_on_save && @svn_path && Rails.env.production?
          svn_file = "#{@svn_path}/#{filename}"
          unless File.exists?(svn_file)
            self.class.create_svn_file(@path, @svn_path)
          else
            self.class.copy_svn_file(@path, @svn_path)
          end

          `svn commit #{svn_file} -m 'Committed #{self.class.name} custom content file'`
        end
      end

      def self.commit
        if Rails.env.production?
          `svn add #{get_default_path}/#{filename}`
          `svn commit #{get_default_path}/#{filename} -m 'Committed #{self.name} content file'`
        elsif @commit_on_save && @svn_path && Rails.env.production?
          svn_file = "#{@svn_path}/#{filename}"

          unless File.exists?(svn_file)
            self.class.create_svn_file(@path, @svn_path)
          else
            self.class.copy_svn_file(@path, @svn_path)
          end

          `svn commit #{svn_file} -m 'Committed #{self.class.name} custom content file'`
        end
      end

      def destroy
        all = self.class.find_all(@path, @parent, @svn_path)
        all.each_with_index do |x,i|
          if x.id == self.id
            all.delete_at(i)
            break
          end
        end
        write_file(all)
        return self
      end

      # Create takes the same attributes as the new method
      # but automatically writes to the file.
      def self.create(a={})
        n = new(a)
        n.save
      end

      # This will make a copy of the default path to the
      # destination path unless the path already exists.
      # It creates the parent path if it doesn't exist yet.
      def self.copy_to(path, svn_path)
        fn = filename
        ffn = "#{self.default_path}/#{fn}"
        tfn = "#{path}/#{fn}"
        unless custom_file_exists?(path)
          #make sure the parent paths exist before copying
          File.makedirs(path)
          @path = path

          # copy the file, but only if the model says to (it says yes by default)
          # ponder this...  CopyDefault is YamlContentBase::CopyDefault, but self::CopyDefault is not YamlContentBase
          if self::CopyDefault
            create_svn_file(path, svn_path) if !svn_path.nil? && Rails.env.production?

            return File.copy(ffn,tfn)
          else
            File.open(tfn,'w'){}
            return true
          end
        end
        return false
      end

      def self.create_svn_file(path, svn_path)
        fn = filename
        ffn = "#{path}/#{fn}"
        sfn = "#{svn_path}/#{fn}"
        if custom_file_exists?(path) && !custom_file_exists?(svn_path)

          #only copy svn file if it is not the same file path as the real file

          unless File.exists?(svn_path)
            File.makedirs(svn_path)
            `svn add #{svn_path}`
            `svn ci #{svn_path} -m 'Check in new custom promotion folder'`
          end

          if sfn != ffn
            File.copy(ffn,sfn)
          end

          `svn add #{sfn}`
          `svn ci #{sfn} -m 'Added new #{self.class.name} custom content file'`
        end
      end

      def self.copy_svn_file(path, svn_path)
        fn = filename
        ffn = "#{path}/#{fn}"
        sfn = "#{svn_path}/#{fn}"
        if custom_file_exists?(path) && custom_file_exists?(svn_path) && sfn != ffn
          File.copy(ffn,sfn)
        end
      end

      def self.filename
        "#{self.to_s.underscore}.yml"
      end

      # Pass this two arguments
      def self.find(*args)
        x = args.first
        h = args.size > 1 ? args.last : {}
        @parent = h[:parent]
        path = h[:path] || ''
        order = (h[:order] || @order || :id).to_sym
        svn_path = h[:svn_path]
        a = find_all(path, @parent, svn_path).sort_by { |b| b.send(order).to_i }
        case x
        when :all then YamlContentBaseArray.new(a, self.to_s, path, @parent, svn_path, @is_backup)
        when :first then a.first
        else a.select {|b| b.id == x.to_i}.first
        end
      end

      def self.custom_file_exists?(path)
        return File.exist?("#{path}/#{filename}")
      end

      def get_default_path
        self.class.default_path
      end

      def self.default_path
        HasYamlContent.base_path.join(DefaultPath).to_s
      end

      def self.get_path(path)
        return self.custom_file_exists?(path) ? path : defined?(@@default_paths) ? @@default_paths[@parent.class.to_s] || self.default_path : self.default_path
      end

      def self.find_all(path, parent, svn_path)
        custom_path = path
        path = get_path(path)
        fn = "#{path}/#{filename}"

        @is_backup = false
        commit_on_save = true

        begin
          result = File.open(fn) { |yf| YAML.load(yf) } || []
        rescue
          result = File.open(fn.gsub('.yml','-backup.yml')) { |yf| YAML.load(yf) } || []
          @is_backup = true
        end

        # Need to inject our path and file instance variables
        # when loading these from the file because this
        # information is not stored in the file

        result.each do |r|
          r.instance_variable_set("@path",path)
          r.instance_variable_set("@svn_path",svn_path)
          r.instance_variable_set("@file",fn)
          r.instance_variable_set("@parent",parent)
          r.instance_variable_set("@is_backup", @is_backup)
          r.instance_variable_set("@commit_on_save", commit_on_save)
          r.instance_variable_set("@order", @order)
        end
      end

      def image_path(full=false, force_custom=false)
        unless @parent.nil? || @parent.is_default?
          if File.exists?(custom_image_path(true)) || force_custom
            custom_image_path(full)
          else
            default_image_path(full)
          end
        else
          default_image_path(full)
        end
      end

      def image_folder(full=false, force_custom=false)
        unless @parent.is_default?
          if !Dir[custom_image_folder(true)].empty? || force_custom
            custom_image_folder(full)
          else
            default_image_folder(full)
          end
        else
          default_image_folder(full)
        end
      end

      def default_image_path(full=false)
        image = Dir["#{default_image_folder(true)}#{id}_versioned_*.jpg"].first
        unless image.nil?
          !full ? image.split("#{Rails.root}/public").last : image
        else
          "#{default_image_folder(full)}#{id}_versioned_#{image_version || 1}.jpg"
        end
      end

      def custom_image_path(full=false)
        "#{custom_image_folder(full)}#{id}_versioned_#{image_version}.jpg"
      end

      def default_image_folder(full=false)
        "#{"#{Rails.root}/public" if full}/images/#{self.type.to_s.downcase.pluralize}/"
      end

      def custom_image_folder(full=false)
        "#{"#{Rails.root}/public" if full}/symlink/#{self.type.to_s.downcase.pluralize}/#{@parent.name.downcase}#{@parent.id}/"
      end

      def save_image(image)
        #delete previous file if it exists
        old_path = image_path(true, !@parent.is_default?)
        if RAILS_ENV == 'production'
          if File.exists?(old_path)
            `svn delete #{old_path}`
            `svn commit #{old_path} -m 'Delete old image for #{self.type.to_s}'`
          end
        else
          File.delete(old_path) if File.exists?(old_path)
        end

        #increment image_version to avoid cacheing issues
        self.send("image_version=",RAILS_ENV == 'production' ? (image_version || 0) + 1 : 1)

        new_path = image_path(true, !@parent.is_default?)
        File.makedirs(image_folder(true, !is_default_path?))

        #write the new image file
        File.open(image_path(true, !is_default_path?),"wb") {|f| f.write(image.read)}

        if RAILS_ENV == 'production'
          `svn add #{image_path(true, !is_default_path?)}`
          puts `svn commit #{image_path(true, !is_default_path?)} -m 'Committed new image for #{self.type.to_s.pluralize}'`
        end
      end

      def respond_to?(m, include_private = false)
        if @parent.is_a?(m.to_s.titleize.constantize)
          true
        else
          super
        end
      rescue
        super
      end

      def method_missing(m,*args)
        if @parent.is_a?( m.to_s.titleize.constantize)
          @parent
        else
          super(m,*args)
        end
      rescue
        super(m,*args)
      end

    end
  end
end
