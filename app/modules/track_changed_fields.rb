# keeps track of fields within a model that have changed
# it does so by overriding the write_attribute method
# in other words, whenever write_attribute is called, this module will keep track of what field was written to
# then, in your model, in an after_save or elsewhere, you can put (for example):
#     has_field_changed(:exercise)  # to see if :exercise has changed
#     have_fields_changed(:exercise,:weight,:etc)  # to see if any NOT all of the listed fields have changed

module TrackChangedFields
  def too_dirty
    @too_dirty||=0
    @too_dirty+=1
  end

  def self.included(base)
    base.send :before_save, :too_dirty
    base.alias_method_chain :reload, :track_changed_fields
  end

  def reload_with_track_changed_fields
    # reloading is OK if we clear these variables
    @too_dirty = 0
    @original_values = {}
    @changed_fields = []
    reload_without_track_changed_fields
  end

  def get_original_value(symbol)
    @too_dirty||=0
    puts "WARNING! #{self.class.to_s}.save called multiple times.  TrackChangedFields may produce incorrect results if you set #{symbol} more than one time.  Invoke .reload if you see an incorrect result." if @too_dirty > 1 

    symbol = symbol.to_sym if symbol.is_a?(String)
    @original_values = {} if @original_values.nil?
    @original_values[symbol] = read_attribute(symbol) unless @original_values.keys.include?(symbol)
    #puts "#{self.to_s} ORIGINAL_VALUE: #{@original_values[symbol]}"
    @original_values[symbol]
  end
  
  def write_attribute(symbol,value)
    changed = false
    original = get_original_value(symbol)
    
    # very carefully checking to see if we're checking to see if a date or time field has changed.  
    # if it is a date field, then let's see if the difference between them is zero
    if (not original.nil?) and 
       (not value.nil?) and 
       (original.class == Date or original.class == Time) and 
       (not (Time.parse(value.to_s) rescue nil).nil?)
      changed = (original.to_time - Time.parse(value.to_s)) != 0
    else
      changed = original != value
    end
    changed_fields << symbol if changed_fields.select{|f| f == symbol}.size == 0 and changed
    super symbol, value
  end

  def changed_fields
    @changed_fields = [] if @changed_fields.nil?
    @changed_fields
  end
  
  def has_field_changed(symbol)
    # note: sometimes changed_fields will contain "strings" and sometimes :symbols
    # it appears to be dependent on whether or not the field in question has validation 
    # or anything else in the class definition that uses the field name in the form of a symbol
    # for example, Entry has validates_presence_of :logged_on, so when logged_on=(val) is called, write_attribute is passed a :symbol
    # however, Entry does not have any validation for the "exercise" field, so write_attribute is passed a "string"
    # that makes this array tricky, because it contains both strings and symbols
    changed_fields.select{|f| f==symbol or f.to_s==symbol.to_s}.size != 0
  end
  
  def have_fields_changed(*symbols)
    changed = false
    symbols.each do |symbol|
      if has_field_changed(symbol)
        changed = true
        break
      end
    end
    changed
  end
end
