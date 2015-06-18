module HesUdf
  # Udf module that adds necessary methods to a dynamic owner user defined field model
  module UDF
    # Extend and include model
    def self.included(base)
      base.send(:extend, ClassMethods)
      base.send(:include, InstanceMethods)
    end

    # Adds class methods for removing dynamically create udf columns
    module ClassMethods
      # Removes all dynamically created udf columns
      def remove_udf_columns
        self.columns[2..self.columns.size].each do |column|
          ActiveRecord::Migration.remove_column self.table_name, column.name
        end

        self.reset_column_information
      end
    end

    # Adds instance methods for owner udf model
    module InstanceMethods

      # Gets all the definitions for the user defined columns
      def udf_defs
        UdfDef.find(:all,:conditions => ["owner_type = ?", self.parent.class.to_s])
      end

      # There's a production problem...
      # The classes are cached, unlike dev
      # So, if you create a Udf, but don't restart mongrel, the field won't be found
      # Therefore, you have to check to see if the column exists
      def method_missing(name, *args, &block)
        fn = name.to_s
        fnne = fn.gsub('=','')
        if (!self.attributes.keys.include?(fnne)) && self.connection.columns(self.class.table_name).map{|c| c.name}.include?(fnne)
          # for next time
          self.class.reset_column_information

          # for this time
          if self.new_record?
            self.attributes[fnne] = nil
          else
            self.attributes[fnne] = self.connection.select_all("select #{fnne} from #{self.class.table_name} where id = #{self.id}")[0][fnne] rescue nil
          end

          return self.attributes[fnne]
        else
          super
        end
      end
    end
  end
end
