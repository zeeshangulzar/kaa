class Udf < ApplicationModel
  
  set_table_name :schema_info  # this kludge is here just go get us out the gate, it will be set properly later on
  
  def udf_defs
    UdfDef.find(:all,:conditions=>["owner_type = ?", self.parent.class.to_s])
  end

  def method_missing(name,*args)
    # there's a production problem...
    # the classes are cached, unlike dev
    # so, if you create a UDF, but don't restart mongrel, the field won't be found
    # therefore, you have to check to see if the column exists
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
      super(name,*args)
    end
  end
end
