module HesReportsYaml
  # HasYamlContent
  module HasYamlContent

    def self.included(base)
      base.extend(ClassMethods)
      @@_content_types ||= {}
      @@_content_types[base.to_s] ||= []
      @@_base_path ||= Rails.root
    end

    def self.base_path
      @@_base_path
    end

    def self.base_path=(path)
      @@_base_path = Pathname.new(path)
    end


    module ClassMethods

      def content_default_path(path)
        YamlContentBase.add_default_path(self.to_s, path)
      end

      def custom_content_types
        h = send(:class_variable_get, :@@_content_types)
        h[self.to_s] ||= []
        h[self.to_s]
      end

      def custom_content_types=(types)
        content_types = custom_content_types
        content_types.merge({self.to_s => types})
        send(:class_variable_set, :@@_content_types, content_types)
      end

      def load_custom_content_module(model_name)
        filepath = HasYamlContent.base_path.join('app','modules','content_models',"#{model_name.singularize.underscore}.rb")
        load filepath if !Object.const_defined?(model_name.singularize.camelize) && File.exists?(filepath)
      end

      #Declares which content models will be included with the model
      #EXAMPLE: has_content :articles, :tips
      def has_yaml_content(*args)
        include HasYamlContent::InstanceMethods

        #get the already loaded content modules
        content_types = custom_content_types
        args.each do |arg|
          #load content model
          if arg.is_a?(Symbol)

            #singularize content model and append to array
            model_name = arg.to_s.singularize.titleize.gsub(" ","")
            content_types << {:name => model_name, :plural => true}

            #try to load the content module if it exists
            load_custom_content_module(arg.to_s)

            #add method so that content can be called like base.tips or base.detail
            define_method(arg.to_s) do
              get_content(model_name)
            end

            #extra options for a content model such as :plural => false, or :class_name => 'PromotionDetail'
          elsif arg.is_a?(Hash)
            content_types[content_types.size - 1] = content_types.last.merge(arg) #append options to last item in array

            #try to load the content module from :class_name
            if arg[:class_name]
              load_custom_content_module(arg[:class_name])
            end
          end
        end

        #insert the new content modules
        custom_content_types = content_types
      end
    end

    module InstanceMethods

      #This method must be overridden in the model that uses this plugin
      #contains the folder path where custom content will be saved
      def custom_content_path
        raise "Custom content path must be defined in the inherited model"
      end

      #short cut to get all content_types
      def content_types
        self.class.custom_content_types
      end

      #returns an array (YamlContentBaseArray) of all the content objects (one YamlContentBase instance if it isn't plural).
      def get_content(model_name)
        @_content ||= {}

        # return content if it has already been memoized
        return @_content[model_name] unless @_content[model_name].nil?

        #get class of content model we are trying to get content for
        model = get_content_model(model_name)

        if is_plural?(model_name)
          content = model.find(:all, :path => custom_content_path, :parent => self)
        else
          content = model.find(:first, :path => custom_content_path, :parent => self)
        end


        # memoize content so we don't parse file again on the same request
        @_content[model_name] = content
      end

      #Gets the content model class
      def get_content_model(model_name)
        model_hash = content_types.select{|x| x[:name] == model_name}.first
        return model_hash[:class_name].nil? ? model_name.constantize : model_hash[:class_name].constantize
      end
      private :get_content_model

      #Checks to see if the association is plural or singular
      def is_plural?(model_name)
        model_hash = content_types.select{|x| x[:name] == model_name}.first
        return model_hash[:plural]
      end
      private :is_plural?
    end
  end
end
