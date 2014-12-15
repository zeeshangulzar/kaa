class UdfDef < ApplicationModel
  include TrackChangedFields

  validates_presence_of :owner_type, :parent_type, :parent_id, :data_type

  validates_format_of :owner_type, :with => /^[a-zA-Z0-9_]+$/, :message => "must be letters, numbers, and underscores only"
  validates_format_of :parent_type, :with => /^[a-zA-Z0-9_]+$/, :message => "must be letters, numbers, and underscores only"
  validates_format_of :parent_id, :with => /^[0-9]+$/, :message => "must be a positive integer"

  def after_validation
    # is owner a class constant?
    o = (Inflector.constantize(self.owner_type) rescue nil)  
    # is parent a class constant?
    p = (Inflector.constantize(self.parent) rescue nil) 
    unless o.nil? || p.nil?
      x = (p.send(:find, self.parent_id) rescue nil)
      unless x.nil?
        # is the parent object what it's supposed to be?
        #self.parent.errors.add "Found #{self.parent.to_s} with id '#{self.parent_id}', but it is not of type #{self.parent.to_s}" unless x.is_a(p)
        self.errors.add :parent,"Found #{self.parent.to_s} with id '#{self.parent_id}', but it is not of type #{self.parent.to_s}" unless x.is_a(p)
      else
        # can the parent object be found?
        #self.parent.errors.add "Could not find #{self.parent.to_s} with id '#{self.parent_id}'"
        self.errors.addi :parent,"Could not find #{self.parent.to_s} with id '#{self.parent_id}'"
      end
    else
      #self.owner_type.errors.add "#{self.owner_type} is not a valid class constant" if o.nil?
      #self.parent.errors.add "#{self.parent} is not a valid class constant" if p.nil?
      self.errors.add :owner_type,"#{self.owner_type} is not a valid class constant" if o.nil?
      self.errors.add :parent,"#{self.parent} is not a valid class constant" if p.nil?
    end
  end

  def orphan?
    !parent
  end

  def parent
    eval(self.parent_type).find(self.parent_id) rescue nil if !self.parent_type.nil? and !self.parent_id.nil?
  end
  
  def after_create
    update_attributes :field_name=>cfn
    # after you create a udf def, create the field
    other = self.data_type.to_sym==:string ? {:limit=>100} : self.data_type.to_sym==:decimal ? {:precision=>10,:scale=>2} : {}
    begin
      ActiveRecord::Migration.add_column self.ctn, self.cfn, self.data_type.to_sym,other
    rescue
      #puts "=========================================================================================="
      puts "#{self.ctn} already has #{self.cfn} -- no need to add again"
      #puts "=========================================================================================="
      #column already exists
    end
  end

  def v1_conventionalized_field_name
    "#{self.parent_type}_#{self.parent_id}"
  end

  def cfnables_to_hash(col='promotion_id')
    @cfnables ||= {}
    return @cfnables unless @cfnables.empty?

    sql = "select id, data_type, owner_type, parent_type, parent_id
           from udf_defs
           where owner_type = '#{owner_type}' and parent_type = '#{parent_type}' and parent_id in (select id from #{parent.class.table_name} where #{col} = #{parent.send(col)})
           order by data_type, id"

    rows = ActiveRecord::Base.connection.select_all(sql)
    rows.each do |row|
      k = row['data_type'].to_sym
      @cfnables[k] ||= []
      @cfnables[k] << row['id'].to_i
    end
    @cfnables 
  end

  def conventionalized_field_name(fn=nil)
    if parent_type == 'CustomPrompt'
      if field_name
        field_name
      else
        index=cfnables_to_hash[data_type.to_sym].index(id)
        "#{parent_type}_#{data_type}_#{index+1}"
      end
    else
      v1_conventionalized_field_name
    end 
  end
  alias_method :cfn, :conventionalized_field_name

  def conventionalized_table_name
    "#{eval(self.owner_type).table_name}_udfs"
  end
  alias_method :ctn, :conventionalized_table_name

  def conventionalize
    return {
             :table_name => ctn,
             :field_name => cfn,
             :data_type => self.data_type.to_sym
           }
  end
end
