module HesReportsYaml
  module HasYamlContent
    class YamlContentBaseArray < Array
      attr_accessor :model_name, :path, :svn_path, :parent, :backup

      #Initializes an array that specifically holds YamlContentBase objects
      #arr: the array of YamlContentBase objects
      #name: the name of the YamlContentBase model
      #path: the custom path for finding, saving, updating, and deleting YamlContentBase objects
      def initialize(arr, name, path, parent, svn_path, backup=false)
        super(arr)
        @model_name = name
        @path = path
        @svn_path = svn_path
        @parent = parent
        @backup = backup
      end

      def errors
        !@backup ? [] : ["There is an error in the #{@model_name.pluralize} content file and an out-of-date version is being used. Please correct error in content through the dashboard or have a programmer find a solution. Users cannot see this message but will still see the older content."]
      end

      #Catches all the methods not declared for this array type object and
      #allows many of the same features as an array of ActiveRecord objects.
      def method_missing(m,*args)
        #find_by_name("John") returns first YamlContentBase object that matches
        if m.to_s.index("find_by") == 0
          attribute = m.to_s.gsub("find_by_","")
          return self.detect{|x| x.send(attribute) == args[0]}
          #find_all_by_name("John") returns array of YamlContentBase objects that match
        elsif m.to_s.index("find_all_by") == 0
          attribute = m.to_s.gsub("find_all_by_","")
          return self.select{|x| x.send(attribute) == args[0]}
        end
        raise "'#{m}' is not a method"
      end

      def build(*args)
        i = @model_name.constantize.new(:path => @path, :parent => @parent, :svn_path => @svn_path)
        i.attributes = args ? args[0] || {} : {}
        i
      end

      def create(*args)
        i = @model_name.constantize.new(:path => @path, :parent => @parent, :svn_path => @svn_path)
        i.update_attributes(args ? args[0] || {} : {})
        i
      end

      def commit
        @model_name.constantize.commit() if @parent.is_default?
        true
      end

      def clone_default
        @model_name.constantize.copy_to(@path, @svn_path) unless is_cloned?
        self.each do |i|
          i.set_custom_path(@path)
          i.set_custom_svn_path(@svn_path)
        end
      end

      def is_cloned?
        @model_name.constantize.custom_file_exists?(@path)
      end

      def use_default
        @path = nil
      end

      #Searches the YamlContentBaseArray for the matching id
      def find(id)
        self.detect{|x| x.id == id.to_i}
      end
    end
  end
end
