  # SelectRows
module SelectTypedRows
  MysqlFieldTypes = {
    0 => :decimal,
    1 => :integer,
    2 => :integer,
    3 => :integer,
    4 => :float,
    5 => :float,
    7 => :datetime,
    8 => :integer,
    9 => :integer,
    10 => :date,
    11=> :time,
    12 => :datetime,
    13 => :integer,
    14 => :date,
    246 => :float,
    247 => :string,
    248 => :string,
    249 =>:binary,
    250 => :binary,
    251 => :binary,
    252 => :binary,
    253 => :string,
    254 => :string,
    255 => :string
  }

  def select_typed_rows(sql, name = nil, include_column_names = false)
    #@connection.query_with_result = true
    
    #result = execute(sql, name)
    result= ActiveRecord::Base.connection.execute(sql)

    hash={:rows=>result.to_a}
    rows=result.to_a
    #fields = result.fetch_fields.collect { |f| [f.name,(f.type == 1 && f.length == 1 ? :boolean : MysqlFieldTypes[f.type] || :string )]}
    # WTF is this gem?  it has F'ing zero documentation and no visible way of telling you what the data types are of the columns

    unless rows.empty?
      hash[:fields]=[] 
      result.fields.each_with_index do |f,i|
        hash[:fields]<<[f]
        item=rows.first[i]
        hash[:fields].last <<
          if item.is_a?(Date)
            :date
          elsif item.is_a?(Time)
            :time
          elsif item.is_a?(TrueClass) || item.is_a?(FalseClass)
            :boolean
          elsif item.is_a?(Fixnum)
            :integer
          elsif item.is_a?(Float) || item.is_a?(BigDecimal)
            :decimal
          else
            :string
          end
      end
    else
      hash[:fields] = result.fields.collect{|f|[f,:string]}
    end

    #rows = []
    #result.each do |r|
    #  r.each_with_index do |f,i|
    #    r[i] = type_cast(fields[i][1],r[i])
    #  end
    #  rows << r
    #end
    #result.free
    
    #{:rows=>rows,:fields=>fields}
    hash
  end

private
  def type_cast(type,value)
    return nil if value.nil?
    case type
      when :string    then value
      when :text      then value
      when :integer   then value.to_i rescue value ? 1 : 0
      when :float     then value.to_f
      when :decimal   then ActiveRecord::ConnectionAdapters::Column.value_to_decimal(value)
      when :datetime  then ActiveRecord::ConnectionAdapters::Column.string_to_time(value)
      when :timestamp then ActiveRecord::ConnectionAdapters::Column.string_to_time(value)
      when :time      then ActiveRecord::ConnectionAdapters::Column.string_to_dummy_time(value)
      when :date      then ActiveRecord::ConnectionAdapters::Column.string_to_date(value)
      when :binary    then ActiveRecord::ConnectionAdapters::Column.binary_to_string(value)
      when :boolean   then ActiveRecord::ConnectionAdapters::Column.value_to_boolean(value)
      else value
    end
  end
end