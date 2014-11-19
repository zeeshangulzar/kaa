# ManyToMany
module ManyToMany
 
  def ManyToMany.init
    # this will find the name of many-to-many classes, and cause creation of the many-to-many class
    # and all necessary relationships
    # otherwise, you might get a constant not found error when you refer to it
    ActiveRecord::Base.connection.tables.select{|t| t.downcase.include?("rel_")}.each do |t|
      classes = t.gsub('rel_','').split('_')
      if classes.size == 2
        classes.each do |c|
            klass = c.singularize.classify
            #puts "Found possible many-to-many relationship: #{klass}"
            klass.constantize rescue nil
        end
      end
    end
    return true
  end
 
  # causes the find method to be overridden safely
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  module ClassMethods
    def many_to_many(*args)
      args = args[0] if args.is_a?(Array) and args[0].is_a?(Hash)
      args = {} unless args.is_a?(Hash)
      raise ":with must be a symbol" unless args[:with]. is_a?(Symbol)
      if args[:primary] || args[:class_name]
        if args[:primary]
          raise ":primary must be a symbol" unless args[:primary].is_a?(Symbol)
          raise ":primary must be either :#{self.to_s.underscore} or :#{args[:with].to_s.classify.underscore}" unless [self.to_s.underscore,args[:with].to_s.classify.underscore].include?(args[:primary].to_s.classify.underscore)
        else
          raise ":class_name must be a string in TitleCase" unless args[:class_name].is_a?(String) && ('A'..'Z').include?(args[:class_name].first)
          #args[:collection]||=args[:class_name].underscore.pluralize
        end
      else
        raise ":primary or :class_name must be specified"
      end

      args[:allow_duplicates]||=false
  
      raise ":fields must be an array" unless args[:fields].nil? || args[:fields].is_a?(Array)
      args[:fields]||=[]
      args[:fields] << [:created_on,:date]
      args[:fields] << [:created_at,:datetime]
      args[:fields] << [:updated_on,:date]
      args[:fields] << [:updated_at,:datetime]

      thisClassConstString = self.to_s
      thisClassConst = thisClassConstString.constantize
      
      primaryClassConstString = nil
      secondaryClassConstString = nil
      if self.to_s == args[:primary].to_s.classify
        primaryClassConstString = self.to_s
        secondaryClassConstString = args[:with].to_s.classify
      else
        primaryClassConstString = args[:with].to_s.classify
        secondaryClassConstString = self.to_s
      end
      primaryClassConst = primaryClassConstString.constantize
      secondaryClassConst = secondaryClassConstString.constantize
      
      self_referencing = primaryClassConst==secondaryClassConst
      
      m2mConstString = args[:class_name] ? args[:class_name] : "#{primaryClassConst}#{secondaryClassConst}"
 
       tableName = (args[:class_name] ? "rel_#{args[:class_name].underscore.pluralize}" : "rel_#{m2mConstString.underscore.split('_').map{|e|e.pluralize}.join('_')}")
       fullTableName = args[:database] ? "#{args[:database]}.#{tableName}" : tableName

      sort = args[:order].nil? ? 
        nil : 
        args[:order].is_a?(Hash) ? 
          # :order=>{:field1=>:desc,:field2=>:asc}
          args[:order].to_a.collect{|x|x[0].is_a?(Symbol) ? "#{fullTableName}.#{x[0]} #{x[1]}" :  x.join(' ')}.join(", ") :
          args[:order].is_a?(Array) ?
            # :order=>["field1 desc", "field2 asc"]
            args[:order].join(", ") :
            args[:order].is_a?(String) ?
              # :order=>"field1 desc, field2 asc"
              args[:order] :
              nil

      puts "WARNING: supply table name #{tableName} when using many-to-many sort option, or specify as Hash such as :order=>{:field=>:desc}, to prevent eager-loading problems." unless sort.nil? || sort =~/#{fullTableName}\./ 
       
      unless Object.const_defined?(m2mConstString)
        connection.execute "use #{args[:database]}" if args[:database]
        
        unless connection.tables.include?(tableName)
          connection.create_table tableName.to_sym do |t|
            t.column "#{self_referencing ? "parent_" : ""}#{primaryClassConstString.underscore}_id", :integer
            t.column "#{self_referencing ? "child_" : ""}#{secondaryClassConstString.underscore}_id", :integer
          end
          connection.add_index tableName, "#{self_referencing ? "parent_" : ""}#{primaryClassConstString.underscore}_id", :name => "by_#{self_referencing ? "parent_" : ""}#{primaryClassConstString.underscore}_id"
          connection.add_index tableName, "#{self_referencing ? "child_" : ""}#{secondaryClassConstString.underscore}_id", :name => "by_#{self_referencing ? "child_" : ""}#{secondaryClassConstString.underscore}_id"
          #puts "#{m2mConstString} table named #{tableName} created...OK"
        else
          #puts "#{m2mConstString} table named #{tableName} found...OK"
        end


        # does a unique index need to be created or dropped?
        unique_index_name = "#{tableName}_unique_index"
        unique_index_exists = !connection.select_all("show indexes from #{tableName} where Key_name = '#{unique_index_name}'").size.zero?
        if args[:allow_duplicates]
          if unique_index_exists
            # we want duplicates, and the unique index exists, so drop it (i.e. :allow_duplicates was not specified originally, but now is)
            connection.remove_index tableName, :name => unique_index_name
            puts "unique index on #{table_name} dropped...OK"
          end
        else
          unless unique_index_exists
            col1 = "#{self_referencing ? "parent_" : ""}#{primaryClassConstString.underscore}_id"
            col2 = "#{self_referencing ? "child_" : ""}#{secondaryClassConstString.underscore}_id"
            connection.add_index tableName, [col1,col2], :name => unique_index_name, :unique => true
            puts "unique index on #{table_name} created...OK"
          end
        end

        
        # are any extra fields specified?  if so, make sure they exist in the table
        unless args[:fields].nil?
          args[:fields].each do |field|
            unless connection.columns(tableName).collect{|c| c.name}.include?(field[0].to_s)
              #puts "creating field #{field[0]} on table #{tableName}..."
              connection.add_column tableName, *field
              #puts "OK"
            else
              #puts "found field #{field[0]} on table #{tableName}"
            end
          end
        end

        # soft delete column?
        if args[:soft_delete] == true && !connection.columns(tableName).collect{|c| c.name}.include?("is_deleted")
          connection.add_column tableName, "is_deleted", :boolean, :default=>false
        end
        
        connection.execute "use #{Rails::Configuration.new.database_configuration[RAILS_ENV]["database"]}" if args[:database]
        
        klass_name = m2mConstString
        klass_new = Class.new(ActiveRecord::Base)
        unless self_referencing
          klass_new.send(:belongs_to, primaryClassConstString.underscore.to_sym)
          klass_new.send(:belongs_to, secondaryClassConstString.underscore.to_sym)
        else
          klass_new.send(:belongs_to, "parent_#{primaryClassConstString.underscore}".to_sym, :class_name=>primaryClassConstString, :foreign_key => "parent_#{primaryClassConstString.underscore}_id")
          klass_new.send(:belongs_to, "child_#{secondaryClassConstString.underscore}".to_sym, :class_name=>secondaryClassConstString, :foreign_key => "child_#{primaryClassConstString.underscore}_id")
        end
        klass_new.send(:validates_presence_of, "#{self_referencing ? "parent_" : ""}#{primaryClassConstString.underscore}_id".to_sym)
        klass_new.send(:validates_presence_of, "#{self_referencing ? "child_" : ""}#{secondaryClassConstString.underscore}_id".to_sym)
        klass = Object.const_set(klass_name,klass_new)
        klass.table_name = fullTableName
        klass.reset_column_information
        # make the destroy method update the is_deleted field instead of totally deleting the record
        # make an undelete method too
        if args[:soft_delete] == true
          klass.instance_eval do
            #remove_method(:destroy)
          end
          klass.class_eval do
            define_method(:destroy) {self.is_deleted = true; self.save;}
            define_method(:undelete) {self.is_deleted = false; self.save}
          end
        end 
        
        columns = klass_new.column_names
        klass_new.send :attr_accessible, *column_names

        columns_privacy = columns.collect{|x|x.to_sym}
        columns_privacy << :public
        klass_new.send :attr_privacy, *columns_privacy

        
        #puts "Created many-to-many relationship between #{primaryClassConstString} and #{secondaryClassConstString} named #{m2mConstString}"
      else
        #puts "Found many-to-many relationship between #{primaryClassConstString} and #{secondaryClassConstString} named #{m2mConstString}"
      end

      # for m2m table
      m2mCollectionName = args[:collection] ? args[:collection] : m2mConstString.underscore.pluralize
      # for destination table
      throughCollectionName = args[:through_collection] ? args[:through_collection] : args[:with].to_s.classify.underscore.pluralize.to_sym

      # if soft deleting: 
      #   make a has_many for the removed records, and name it, for example, deleted_trip_activities
      #   make a has_many for all records, regardless of whether they're removed or not, and name it, for example, all_trip_activities
      if args[:soft_delete] == true
        unless self_referencing
          thisClassConst.send(:has_many, "all_#{m2mCollectionName}".to_sym, :class_name => m2mConstString, :dependent=>:destroy, :order=>sort)
          thisClassConst.send(:has_many, "all_#{throughCollectionName}".to_sym, :through => "all_#{m2mCollectionName}".to_sym, :source => args[:with], :order=>sort)

          thisClassConst.send(:has_many, m2mCollectionName.to_sym, :class_name => m2mConstString, :dependent=>:destroy, :conditions => ["#{fullTableName}.is_deleted is null or #{fullTableName}.is_deleted = ?",false], :order=>sort)
          thisClassConst.send(:has_many, throughCollectionName.to_sym, :source => args[:with], :through => m2mCollectionName.to_sym, :conditions => ["#{fullTableName}.is_deleted is null or #{fullTableName}.is_deleted = ?",false], :order=>sort)

          thisClassConst.send(:has_many, "removed_#{m2mCollectionName}".to_sym, :class_name => m2mConstString, :dependent=>:destroy, :conditions => ["#{fullTableName}.is_deleted = ?",true], :order=>sort)
          thisClassConst.send(:has_many, "removed_#{throughCollectionName}".to_sym, :through => "removed_#{m2mCollectionName}".to_sym, :source => args[:with].to_sym, :conditions => ["#{fullTableName}.is_deleted = ?",true], :order=>sort)
        else
          thisClassConst.send(:has_many, "all_#{m2mCollectionName}".to_sym, :class_name => m2mConstString, :dependent=>:destroy, :foreign_key => "parent_#{primaryClassConstString.underscore}_id", :order=>sort)
          thisClassConst.send(:has_many, "all_#{throughCollectionName}".to_sym, :through => "all_#{m2mCollectionName}".to_sym, :source => "child_#{args[:with]}", :class_name=>secondaryClassConstString, :order=>sort)

          thisClassConst.send(:has_many, m2mCollectionName.to_sym, :class_name => m2mConstString, :dependent=>:destroy, :conditions => ["#{fullTableName}.is_deleted is null or #{fullTableName}.is_deleted = ?",false], :foreign_key => "parent_#{primaryClassConstString.underscore}_id", :order=>sort)
          thisClassConst.send(:has_many, throughCollectionName.to_sym, :source => "child_#{args[:with]}", :through => m2mCollectionName.to_sym, :conditions => ["#{fullTableName}.is_deleted is null or #{fullTableName}.is_deleted = ?",false], :class_name=>secondaryClassConstString, :order=>sort)

          thisClassConst.send(:has_many, "removed_#{m2mCollectionName}".to_sym, :class_name => m2mConstString, :dependent=>:destroy, :conditions => ["#{fullTableName}.is_deleted = ?",true], :foreign_key => "parent_#{primaryClassConstString.underscore}_id", :order=>sort)
          thisClassConst.send(:has_many, "removed_#{throughCollectionName}".to_sym, :through => "removed_#{m2mCollectionName}".to_sym, :source => "child_#{args[:with]}", :conditions => ["#{fullTableName}.is_deleted = ?",true], :class_name=>secondaryClassConstString, :order=>sort)
        end
      else
        unless self_referencing
          thisClassConst.send(:has_many, m2mCollectionName.to_sym, :class_name => m2mConstString, :dependent=>:destroy, :order=>sort)
          thisClassConst.send(:has_many, throughCollectionName.to_sym, :through => m2mCollectionName.to_sym, :source => args[:with], :order=>sort)
        else
          thisClassConst.send(:has_many, m2mCollectionName.to_sym, :class_name => m2mConstString, :dependent=>:destroy, :foreign_key => "parent_#{primaryClassConstString.underscore}_id", :order=>sort)
          thisClassConst.send(:has_many, throughCollectionName.to_sym, :through => m2mCollectionName.to_sym, :source => args[:with], :source=>"child_#{args[:with]}", :class_name=>secondaryClassConstString, :order=>sort)
        end
      end

      # make some nice add and remove methods
      thisClassConst.class_eval do
        cn = args[:collection] ? args[:collection].to_s.underscore : args[:class_name] ? m2mConstString.underscore : args[:with]
        define_method("add_#{cn}".to_sym) {|a,*h| h[0]||={}; self.send(m2mConstString.underscore.pluralize.to_sym).send(:create,h.first.merge({args[:with].to_sym => (a.is_a?(Numeric) ? args[:with].to_s.classify.constantize.find(a) : a)})) }
        define_method("save_#{cn}".to_sym) {|a,*h| h[0]||={}; x=self.send(m2mConstString.underscore.pluralize.to_sym).send("find_or_create_by_#{self_referencing ? "parent_" : ""}#{self.class.to_s.underscore}_id_and_#{self_referencing ? "child_" : ""}#{args[:with].to_s.classify.constantize.to_s.underscore}_id",self.id, a.is_a?(Numeric) ? a : a.id); x.update_attributes(h.first); x }
        define_method("remove_#{cn}".to_sym) {|a| self.send(m2mConstString.underscore.pluralize.to_sym).send("find_all_by_#{self_referencing ? "child_" : ""}#{secondaryClassConstString.underscore}_id",(a.is_a?(Numeric) ? a : a.id)).each{|x|x.destroy} }
      end
    end
  end
end
