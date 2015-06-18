require File.dirname(__FILE__) + '/udfable'
require File.dirname(__FILE__) + '/udf'
require File.dirname(__FILE__) + '/udf_def_validator'


module HesUdf
  # Engine for initializing hes-udf
  class Engine < ::Rails::Engine

    #initializer "hes-udfs" do	|app|

      ActiveRecord::Base.connection.tables.select{|t| t.downcase.include?("_udfs")}.each do |t|
        table = t[0..(t.index("_udfs")-1)].capitalize.singularize rescue nil
        table.constantize rescue nil
      end

      ActiveRecord::Base.send(:include, HesUdf::Udfable)
   #end
  end
end
