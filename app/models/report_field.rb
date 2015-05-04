class ReportField
  extend ActiveModel::Naming if defined?(ActiveModel::Naming)
  include ActiveModel::Conversion if defined?(ActiveModel::Conversion)
  
  attr_accessor :id, :category, :sql_phrase, :sensitive, :sequence, :join, :filterable, :visible, :role, :display_name, :aggregate, :identification
  
  BOOLEAN_ATTRIBUTES = [:sensitive, :filterable, :visible, :aggregate, :identification]

  def initialize(attributes={})
    attributes = attributes.inject({}){|attribute,(k,v)| attribute[k.to_sym] = v; attribute}

    defaults = {:display_name => "New Field",
              :sql_phrase => "stats.",
              :join => "",
              :sensitive => false,
              :filterable => true,
              :visible => true,
              :identification => false,
              :sequence => -1,
              :role => HesAuthorization::AuthRole.auth_roles[:coordinator]}

    defaults.merge(attributes).each_pair do |k, v|
      send("#{k.to_s}=", BOOLEAN_ATTRIBUTES.include?(k.to_sym) ? v == '1' || v == 'true' || v == true || v == 1 : v)
    end
  end
  
  def update_attributes(_attributes={})
    _attributes.each_pair do |k, v|
      send("#{k.to_s}=", BOOLEAN_ATTRIBUTES.include?(k.to_sym) ? v == '1' || v == 'true' || v == true || v == 1 : v)
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