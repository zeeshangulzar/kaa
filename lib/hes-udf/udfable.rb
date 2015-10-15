module HesUdf
  # Module to include that makes allows a model to have user defined fields. Prompts app to create
  # a udf table that ties model and udf definitions together.
  module Udfable
    # Extend model if UDFable class methods
    def self.included(base)
      base.send(:extend, UdfableClassMethods)
    end

    # Module included so a model can be made udfable
    module UdfableClassMethods

      # Marks a model as udfable
      # @param [Hash] options for customizing user defined fields
      # @example
      #  udfable
      #  udfable :class_name => 'mice'
      #  udable :class_name => 'mice', :table_name => 'mouse'
      def udfable(options = {})
        options = {:class_name => self.to_s, :table_name => self.table_name}.merge(options || {})

        # Add udfable models to module so it can be used in generating migrations
        HesUdf.udfable_models ||= []
        HesUdf.udfable_models << self

        # Use a naming convention...
        udf_table_name = "#{options[:table_name].singularize}_udfs"

        # Check to make sure UdfDef table and custom Udf table for this model have been created in the database
        check_for_table_existence(udf_table_name)

        # Initialize custom udf class for this model
        udf_class = init_udf_class(options[:class_name], udf_table_name)

        # Create a has_one relationship for the udf table created for this model
        self.has_one :udfs, :class_name => udf_class, :dependent => :destroy

        # Create a has_many relationship with UdfDef table
        self.send(:include, UdfableInstanceMethods)
      end

      # Checks to see if UdfDef and Udf table tied to his model have been created.
      # No error is thrown if they don't exist but user will be warned.
      # @param [String] udf_table_name of table tied to udfable model
      def check_for_table_existence(udf_table_name)
        # see if the udf definitions table exists, create it if it doesn't
        unless connection.tables.include?("udf_defs")
          # connection.create_table def_table_name.to_sym do |t|
          #   t.column "owner_type", :string, :limit => 30
          #   t.column "parent_type", :string, :limit => 30
          #   t.column "parent_id", :integer
          #   t.column "data_type", :string
          #   t.column "is_enabled", :boolean, :default => 1
          # end
          # connection.add_index def_table_name, ["parent_type","parent_id"], :name => "by_parent_type_parent_id"
          # UdfDef.reset_column_information
          # puts "Udf definitions table created...OK"

          puts "UDF definitions table must be created before using hes-udf. Please run 'rails generate hes:udf' and 'rake db:migrate'"
        else
          #puts "Udf definitions table found...OK"
        end

        # see if the udf table exists, create it if it doesn't
        unless connection.tables.include?(udf_table_name)
          # connection.create_table udf_table_name.to_sym do |t|
          #   t.column "#{args[:class_name].downcase}_id", :integer
          # end
          # connection.add_index udf_table_name, "#{args[:class_name].downcase}_id", :name=>"by_#{args[:class_name].downcase}_id"
          # puts "Udf table created for model #{self.to_s}...OK"

          puts "#{udf_table_name} table must be created before using hes-udf. Please run 'rails generate hes:udfable' and 'rake db:migrate'"
        else
          #puts "Udf table found for model #{self.to_s}...OK"
        end
      end

      # Initializes custom UDF class for this model
      # @param [String] class_name of custom udf model
      # @param [String] udf_table_name of the custom udf table
      # @return [Class] custom udf class inherited from Udf
      def init_udf_class(class_name, udf_table_name)
        class_symbol = class_name.downcase.to_sym

        # Make a new class def, like Udf, but named, for example, EntryUdf
        klass_name = "#{class_name}Udf"
        klass_new = Class.new(ActiveRecord::Base)

        klass_new.send(:include, HesUdf::UDF)
        klass_new.send(:belongs_to, class_symbol)
        klass_new.send(:alias_method, :parent, class_symbol)
        klass_new.send(:table_name=, udf_table_name)
        klass_new.send(:attr_accessible,:all)

        klass = Object.const_set(klass_name, klass_new)
        klass.reset_column_information
klass.attr_protected
        klass
      end

    end

    # UDFable instance methods
    module UdfableInstanceMethods
      # Creates has many relationship with udf definitions using a method since there is no foreign key to connect the tables
      # @return [Array<UdfDef>] user defined field definitions that match the class of this model
      # @note Caches udf definitions after first call
      def udf_defs
        @udf_defs ||= UdfDef.find(:all, :conditions => ["owner_type = ?", self.class.to_s])
      end
    end
  end
end
