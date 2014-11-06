# Flaggable
module Flaggable
  
  FlagDefTableName = 'flag_defs'
  FlaggableKeys = [String,Symbol]
  FlaggableTypes = [FalseClass,TrueClass,NilClass]
  DefaultableTypes = [FalseClass,TrueClass]
  # gotta be 63 bits.  64th bit is for sign.  not sure if using "bigint unsigned" is cross-platform compliant
  MaxBits=63
  
  # causes the find method to be overridden safely
  def self.included(base)
    base.extend(ClassMethods)
    base.send(:before_save,:flags_resync)
  end
  
  # this is the method that returns a hash of flags along with their values, such as
  # {:is_optionX_enabled => true, :is_optionY_enabled => false}
  def flags
    unless @flags
      # make a hash where everything's false
      @flags=Hash[*self.class.visible_flags.collect{|x|[(x.flag_type=='Symbol' ? x.flag_name.to_sym : x.flag_name),nil]}.flatten]
      # loop through the flag defs setting the flags
      self.class.visible_flags.each do |f|
        sym = (f.flag_type=='Symbol' ? f.flag_name.to_sym : f.flag_name)
        i,p,v = self.class.index_position_value(f.position)
        sn=self.send("flags_#{i}")||0
        @flags[sym] = sn & v > 0
      end
    end
    @flags
  end
  
  def flags=(new_flags)
    new_flags.each_pair do |k,v|
      flags[k] = v unless flags[k].nil?
    end
  end
  
  # this is the method that turns the (potentially-changed) flags back into their bigint values
  # this is intended to be run just before save, in a before_save callback (see self.included)
  def flags_resync
    if @flags
      self.class.flag_def.each do |f|
        sym = (f.flag_type=='Symbol' ? f.flag_name.to_sym : f.flag_name)
        i,p,v = self.class.index_position_value(f.position)
        sn=self.send("flags_#{i}")||0
        b = sn & v > 0
        logger.warn "#{@flags[sym].class} value '#{@flags[sym]}' for flag #{self.class}->#{sym} will be stored as true, not '#{@flags[sym]}'" unless FlaggableTypes.include?(@flags[sym].class)
        if @flags[sym] && !b
          self.send("flags_#{i}=",sn+v)
        elsif b && !@flags[sym]
          self.send("flags_#{i}=",sn-v)
        end
      end
    end
    @flags
  end
  
  module ClassMethods
        def initialize
          @@visible_flags||={}
          @@visible_flags[self.to_s]||=[]
          unless self.constants.include?('FlaggableInitialized')
            initialize_flag_definitions_table
            initialize_flag_fields_for_self
            self.const_set('FlaggableInitialized',true)
          end
        rescue
          #need to catch errors when deploying a new app
        end
        
        # see if the flag definitions table exists, create it if it doesn't
        def initialize_flag_definitions_table
          # start drop this later
          if connection.tables.include?(FlagDefTableName) && !connection.columns(FlagDefTableName).detect{|x|x.name=='id'}
            connection.drop_table FlagDefTableName
          end
          # end drop this later
          
          unless connection.tables.include?(FlagDefTableName)
            connection.create_table FlagDefTableName.to_sym do |t|
              t.column "model", :string, :limit => 100
              t.column "position", :integer
              t.column "flag_name", :string, :limit => 100
              t.column "flag_type", :text, :limit => 6
              t.column "default", :boolean, :default => false
            end
            connection.add_index FlagDefTableName, ["model"], :name => "by_model"
            puts "Flag definitions table created...OK"
          else
            #puts "Flag definitions table found...OK"
          end
        end
        
        def initialize_flag_fields_for_self
          # limited to MaxBits bits, so make flags_1, flags_2 etc so that you have enough space to store all flags (most likely will be < MaxBits)
          n=flag_def.collect(&:position).sort.last||1
          i = [(n/MaxBits.to_f).ceil,1].max      
          i.times do |n|
            fn="flags_#{n+1}"
            pos_range=(((n*MaxBits)+1)..((n*MaxBits)+MaxBits)).to_a
            default=flag_def.select{|x|pos_range.include?(x.position)}.collect{|x|x.default ? 2**(x.position%MaxBits) : 0}.sum
            col=connection.columns(self.table_name).detect{|x|x.name==fn}
            # new flag?
            if !col
              puts "Adding #{fn} to #{self.table_name}"
              ActiveRecord::Migration.add_column self.table_name, fn, :bigint, :default => default
              self.reset_column_information
            # not a good place to set this!!!  do it in xFlag
            # existing flag, but default has changed?
            #elsif self.new.send(fn) != default
            #  puts "Changing default value of #{self.table_name}.#{fn} to #{default}"
            #  ActiveRecord::Migration.change_column self.table_name, fn, :bigint, :default => default
            #  self.reset_column_information
            end
          end
        end
        
        def flags(*args)
          if args.last.is_a?(Hash)
            args.each {|a| flag *[a,args.last] unless a==args.last}
          else
            args.each {|a| flag *a}
          end
        end
        
        def flag(*args)
          if args.is_a?(Array)
            if args[1].is_a?(Hash)
              xFlag(args[0],args[1][:default],args[1][:update_existing])
            else
              xFlag(args[0],false)
            end
          else
            xFlag(args,false)
          end
        end
        
        def xFlag(name,default=false,update_existing=false)
          return if $0 =~ /rake$/
          initialize
          raise "Flag must be a Symbol or String.  #{name.class} '#{name}' is not allowed." unless FlaggableKeys.include?(name.class)
          raise "Flag default must be true or false.  #{default.class} '#{default}' is not allowed." unless DefaultableTypes.include?(default.class)
          f=self.flag_def.detect{|x|x.flag_type==name.class.to_s && x.flag_name==name.to_s}
          i,p,v = index_position_value(f.position) if f

          # new flag?
          if !f
            puts "Adding new flag '#{':' if name.is_a?(Symbol)}#{name}' with default value #{default}"
            new_position=(flag_def.collect(&:position).sort.last||0)+1
            f=FlagDef.create(:model=>self.to_s,:position=>new_position,:flag_name=>name.to_s,:flag_type=>name.class.to_s,:default=>default)
            i,p,v = index_position_value(f.position)
            reset_flag_def
            initialize_flag_fields_for_self
            # find all selfs and set the flag to true, if the default is true (if default is false, nothing to do)
            if update_existing && default == true
              #self.find(:all).each do |each_self|
                # must do this in SQL, not ruby
                # the entire collection of flags has not been loaded, so at this point you do not know what all the rest of the flags are or should be!
                sql = "update #{self.table_name} set flags_#{i} = flags_#{i} + #{v}"
                puts "SETTING #{name.to_s} flag to #{default} [#{sql}]"
                connection.execute sql 
              #end
            end
          end

          # has default changed?
          if f.default!=default
            # first update the flag def
            f.update_attributes(:default=>default)
          end

          # does the table need to be altered for the new default?
          # do not set the default according to the @@flag_def collection -- it may not be fully loaded and you may mess up the default!
          # you need to + or - the default value only if the default for THIS flag is not correct!
          col=connection.columns(self.table_name).detect{|x|x.name=="flags_#{i}"}
          raise "column flags_#{i} not found!" unless col
          new_default = 
            if (default && (col.default & v == 0))
              # default isn't, but should be, true
              col.default + v
            elsif ((!default) && (col.default & v > 0))
              # default is, but shouldn't be, true
              col.default - v
            end
          if new_default
            sql = "alter table #{self.table_name} modify flags_#{i} bigint default #{new_default}"
            puts "ALTERING #{self.table_name}, setting #{name.to_s} flag to #{default} [#{sql}]" 
            connection.execute sql
          end

          initialize_flag_fields_for_self

          @@visible_flags[self.to_s]<<f
    end
  
    # this is a class variable because you don't want to hit the database for something that isn't going to change
    def flag_def
      @@flag_def||=reset_flag_def
      @@flag_def[self.to_s]||[]
    end

    def reset_flag_def
      #@@flag_def = FlagDef.find(:all,:conditions=>["model=?",self.to_s],:order=>"position")
      @@flag_def = {}
      FlagDef.find(:all,:order=>"model,position").each do |fd|
        @@flag_def[fd.model]||=[]
        @@flag_def[fd.model] << fd 
      end
      @@flag_def
    rescue
      {}
    end
    
    def visible_flags
      @@visible_flags[self.to_s]
    rescue
      []
    end

    # turns the Nth flag into flag_i, positionN, and value
    # example: 5th flag  = field name flag_1, bit position 4, true value 2^4
    # example: 63rd flag = field name flag_1, bit position 62, true value 2^62
    # example: 64th flag = field name flag_2, bit position 1, true value 2^0
    def index_position_value(position)
      i=((position)/MaxBits.to_f).ceil
      p=((position-1)%MaxBits)
      v=2**p
      [i,p,v]
    end
  end
end
