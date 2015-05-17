class ReportJoin
  extend ActiveModel::Naming if defined?(ActiveModel::Naming)
  include ActiveModel::Conversion if defined?(ActiveModel::Conversion)
  
  attr_accessor :id, :alias, :sql, :parentof, :childof, :nest_level

  def initialize(attributes={})
    attributes = attributes.inject({}){|attribute,(k,v)| attribute[k.to_sym] = v; attribute}

    defaults = {:alias => nil,
              :sql => nil,
              :parentof => nil,
              :childof => nil,
              :nest_level => 0}

    defaults.merge(attributes).each_pair do |k, v|
      send("#{k.to_s}=", k.to_s == 'nest_level' ? v.to_i : v)
    end
  end
  
  def update_attributes(_attributes={})
    _attributes.each_pair do |k, v|
      send("#{k.to_s}=", k.to_s == 'nest_level' ? v.to_i : v)
    end
    true
  rescue
    false
  end
  
  def attributes
    a = {}
    instance_variables.each do |k|
      a[k.gsub('@', '').to_sym] = self.send(k.gsub('@', '')) unless ['@report_setup'].include?(k)
    end  
    a
  end
  
  def symbolize
    _attributes = attributes.dup
    _attributes.delete(:id)
    _attributes
  end
  
  def persisted?
    !id.nil?
  end
  
  def new_record?
    return id.nil?
  end
  
end