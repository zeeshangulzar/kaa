# UserDefinedFields
module UserDefinedFields

  # commenting these out to make sure it executes..
  #def UserDefinedFields.init
    # this will find the name of udfable classes, and cause creation of the UDF class
    # otherwise, you might get a constant not found error when you refer to it
    ActiveRecord::Base.connection.tables.select{|t| t.downcase.include?("_udfs")}.each do |t|
      table = t[0..(t.index("_udfs")-1)].capitalize.singularize rescue nil
      #puts "Found udfable class: #{table}"
      table.constantize rescue nil
    end
    #return true
  #end
 
  # causes the find method to be overridden safely
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  def udf_defs
    UdfDef.find(:all,:conditions=>["owner_type = ?", self.class.to_s])
  end
  
  module ClassMethods
    def udfable(*args)
      args = {} unless args.is_a?(Hash)
      
      # pass in class_name if it's not easy to pluralize/singularize like mice or bacterium
      args[:class_name]   ||= self.to_s
      args[:class_symbol]   = args[:class_name].downcase.to_sym
      
      # pass in table_name if necessary (it probably never is)
      args[:table_name]   ||= self.table_name 
      
      $udfable = {} if $udfable.nil?
      $udfable[self.to_s.to_sym] = args
      
      # use a naming convention...
      base_table_name = args[:table_name]
      def_table_name = "udf_defs"
      udf_table_name = "#{base_table_name}_udfs"

      # see if the udf definitions table exists, create it if it doesn't
      unless connection.tables.include?(def_table_name)
        connection.create_table def_table_name.to_sym do |t|
          t.column "owner_type", :string, :limit => 30
          t.column "parent_type", :string, :limit => 30
          t.column "parent_id", :integer
          t.column "data_type", :string
          t.column "is_enabled", :boolean, :default => 1
          t.column "field_name", :string
        end
        connection.add_index def_table_name, ["parent_type","parent_id"], :name => "by_parent_type_parent_id"
        UdfDef.reset_column_information
        puts "UDF definitions table created...OK"
      else
        #puts "UDF definitions table found...OK"
        # JS 2014-06-18 - part of condensing the _udfs table is to store the conventionalized_field_name on the UDFDef
        unless connection.columns(def_table_name).collect(&:name).include?('field_name')
          ActiveRecord::Migration.add_column def_table_name, 'field_name', :string
        end
      end
      
      # see if the udf table exists, create it if it doesn't
      unless connection.tables.include?(udf_table_name)
        connection.create_table udf_table_name.to_sym do |t| 
          t.column "#{args[:class_name].downcase}_id", :integer
        end
        connection.add_index udf_table_name, "#{args[:class_name].downcase}_id", :name=>"by_#{args[:class_name].downcase}_id"
        puts "UDF table created for model #{self.to_s}...OK"
      else
        #puts "UDF table found for model #{self.to_s}...OK"
      end

      # make a new class def, like UDF, but named, for example, EntryUDF
      klass_name = "#{args[:class_name]}UDF"
      klass_new = Class.new(UDF)
      klass_new.send(:belongs_to, args[:class_symbol])
      klass_new.send(:alias_method, :parent, args[:class_symbol])
      klass = Object.const_set(klass_name,klass_new)
      klass.table_name = udf_table_name
      klass.reset_column_information

      # this class "has one" of the newly created class
      self.has_one :udfs, :class_name => klass_name, :dependent => :destroy

      if self.to_s == 'Profile' || self.to_s == 'Evaluation'
        klass_name = "Legacy#{args[:class_name]}UDF"
        klass_new = Class.new(UDF)
        klass_new.send(:belongs_to, args[:class_symbol])
        klass_new.send(:alias_method, :parent, args[:class_symbol])
        klass = Object.const_set(klass_name,klass_new)
        klass.table_name = "#{udf_table_name}_backup_20140618"
        klass.reset_column_information

        # this class "has one" of the newly created class
        self.has_one :legacy_udfs, :class_name => klass_name, :dependent => :destroy
      end
    end
  end
end
