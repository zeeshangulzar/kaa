class Report < HesReportsYaml::HasYamlContent::YamlContentBase
  include SelectTypedRows

  attr_accessor :report_type
  attr_accessor :name
  attr_accessor :friendly_url_key
  attr_accessor :fields
  attr_accessor :filters
  attr_accessor :limit
  attr_accessor :sql
  attr_accessor :created_by_master
  attr_accessor :category

  CopyDefault=false

  ReportType_SQL = 'SQL'
  ReportType_Simple = 'Simple'

  # these tables are one-to-manys
  # they repeat in the dropdown, such as Completed 1st Evaluation On or Team Name (1st Competition)
  # the table probably needs to have a sequence column to order the records (see competitions and/or promotion_evaluations)
  OneToManyTables = ['evaluations','competitions']

  # Categories
  Categories = ['Participant Fields', 'Program Fields', 'Registration Fields', 'Evaluation N Fields', 'Competition N Fields']

  Signs = {
    :is => {:display_name=>'is', :sign=>'='},
    :is_not => {:display_name=>'is not', :sign=>'<>'},
    :greater => {:display_name=>'is greater than', :sign=>'>'},
    :greater_equal => {:display_name=>'is greater than or equal to', :sign=>'>='},
    :less => {:display_name=>'is less than', :sign=>'<'},
    :less_equal => {:display_name=>'is less than or equal to', :sign=>'<='},
    :starts_with => {:display_name=>'starts with', :sign=>'like'}
  }

  def initialize(a={})
    super
    self.attributes = a
    self.fields||=[]
    self.filters||={:hashes=>[]}
  end

  # Method to override the default YAML settings
  def to_yaml_properties
    return ['@id','@report_type','@name','@fields','@filters','@limit','@sql','@created_by_master','@friendly_url_key']
  end

  def attributes
    return { :report_type => report_type, :name => name, :fields => fields, :filters => filters, :limit => limit, :sql => sql, :created_by_master => created_by_master, :friendly_url_key => friendly_url_key }
  end

  def attributes=(attributes)
    @report_type = attributes[:report_type] unless attributes[:report_type].nil?
    @name = attributes[:name] unless attributes[:name].nil?
    @fields = attributes[:fields] unless attributes[:fields].nil?
    @filters = attributes[:filters] unless attributes[:filters].nil?
    @limit = attributes[:limit] unless attributes[:limit].nil?
    @sql = attributes[:sql] unless attributes[:sql].nil?
    @created_by_master = attributes[:created_by_master] unless attributes[:created_by_master].nil?
    @friendly_url_key = attributes[:friendly_url_key] unless attributes[:friendly_url_key].nil?
  end

  def update_attributes(attributes)
    self.attributes = attributes
    save
  end

  def self.typeof
    return Report
  end

  # chop down this method to remove params and session
  def quick_get_data(promotion, h = {})
    rh = {}

    r,o,p = promotion.organization.reseller_id,promotion.organization_id,promotion.id
    if h[:promotion]
      r,o,p = h[:promotion].split('/')
      r = promotion.organization.reseller_id unless @user.role==User::Role[:master]
      o = promotion.organization_id unless [User::Role[:master],User::Role[:reseller]].include?(@user.role)
    end
    rh[:reseller_id] = r unless r=="*"
    rh[:organization_id] = o unless o=="*"
    rh[:promotion_id] = p unless p=="*"

    filter_promo = p==promotion.id ? promotion : p!="*" ? Promotion.find(p) : nil

    rh[:reported_on_min] = h[:reported_on_min] ? Date.parse(h[:reported_on_min]) : [(filter_promo||promotion).users.entries.minimum(:recorded_on)||Date.today,Date.today].min
    rh[:reported_on_max] = h[:reported_on_max] ? Date.parse(h[:reported_on_max]) : [(filter_promo||promotion).users.entries.maximum(:recorded_on)||Date.today,Date.today].min

    self.filters[:hashes] = []
    self.filters[:special] = rh
    self.use_setup(promotion.report_setup)
    return self.get_data
  end

  def get_data
    #puts "================================================================================"
    #now = Time.now
    #puts Time.now.to_s
    reportSql = to_sql

    # data = []
    # ActiveRecord::Base.connection.execute(reportSql).each do |row|
    #   data << row
    # end
    #puts self.name
    #puts "Time.now.to_s (#{Time.now-now} seconds elapsed)"
    data = select_typed_rows(reportSql)
    #data = Stat.connection.execute(reportSql)
    #puts "Time.now.to_s (#{Time.now-now} seconds elapsed)"
    #puts "================================================================================"
    return data
  end

  def get_setup
    return @setup
  end
  def use_setup(setup)
    @setup = setup
  end

  def promotionize(promotion)
    @setup=promotion.report_setup

    # posted variable looks like this: 28|1 (where 28 is the report setup field id and 1 is the sequence)
    #first_o2m_field = fields.detect{|f|f.include?('|') && !f.include?('_udfs')}||filters[:hashes].detect{|h|h[:field].include?('|') && !h[:field].include?('_udfs')}[:field]||'|' rescue '|'
    #f = first_o2m_field.split('|').first
    #seq = first_o2m_field.split('|').last
    #o2mId = first_o2m_field.split(':').last.split('-').last.split('|').first
    @setup.fields = @setup.add_one_to_many_fields(@setup.fields,promotion)

    # posted variable looks like this: profiles_udfs:27 evaluations_udfs:27|1  (where 27 is the custom prompt id and 3 is pev id)
    #first_udf_field = fields.detect{|f|f.include?('evaluations_udfs')||f.include?('profiles_udfs')}||':|'
    @setup.fields = @setup.add_custom_prompts(@setup.fields,promotion)
    # @setup.fields = @setup.add_locations(@setup.fields, promotion)
    @setup.fields = @setup.add_other_promotion_specific_fields(@setup.fields,promotion)
  end

  def to_sql
    # if you don't promotionize, then you'll be using the default setup
    @setup ||= ReportSetup.find(:first)

    if report_type == ReportType_SQL
      # user might specify :conditions_with_where, in which case we are to supply the where clause
      # 'select * from stats :conditions_with_where group by location'
      # user might specify :conditions_with_and, in which case we are to supply the and operator
      # 'select * from stats where gender = 'F' :conditions_with_and group by location'
      new_sql = sql

      # the where clause only involving hash filters (e.g. the drop-down filters)
      where_hashes_only = sql_where_from_hashes(filters[:hashes]||[]).strip
      clause_combos(new_sql,:hash_conditions,where_hashes_only)

      where = sql_where(filters)

      # the entire where clause as determined by the special_filters
      clause_combos(new_sql,:conditions,where)

      # the location conditions, if any
      if new_sql.include?(':location_conditions')
        clause = []
        clause << "users.location_id = '#{filters[:special][:location].to_s}'" if filters[:special][:location]
        clause << "users.top_level_location_id = '#{filters[:special][:top_level_location].to_s}'" if filters[:special][:top_level_location]
        clause = clause.join(' and ')
        clause_combos(new_sql,:location_conditions,clause)
      end

      # individual conditions
      new_sql.gsub!(":reported_on_min","'#{filters[:special][:reported_on_min].to_s}'")
      new_sql.gsub!(":reported_on_max","'#{filters[:special][:reported_on_max].to_s}'")
      new_sql.gsub!(":reseller_id","'#{filters[:special][:reseller_id].to_s}'")
      new_sql.gsub!(":organization_id","'#{filters[:special][:organization_id].to_s}'")
      new_sql.gsub!(":promotion_id","'#{filters[:special][:promotion_id].to_s}'")
      new_sql.gsub!(":location_id","'#{filters[:special][:location].to_s}'")
      new_sql.gsub!(":top_level_location_id","'#{filters[:special][:top_level_location].to_s}'")

      joins = sql_joins([],filters[:hashes])
      new_sql.gsub!(":joins",joins)

      # is there a having clause?
      if new_sql.include?(':having')
        having = sql_having_from_hashes(filters[:hashes]||[]).strip
        new_sql.gsub!(':having'," HAVING #{having} ")
      end

      return new_sql
    else
      return make_sql
    end
  end

  def clause_combos(clause,placeholder,replacement)
    empty = clause.gsub('_with_or','').gsub('_with_and','').gsub('_with_where','').include?(":#{placeholder}_unless_empty") && replacement.strip.empty?
    clause.gsub!(":#{placeholder}_with_or_unless_empty", empty ? '' : ":#{placeholder}_with_or")
    clause.gsub!(":#{placeholder}_with_and_unless_empty", empty ? '' : ":#{placeholder}_with_and")
    clause.gsub!(":#{placeholder}_with_where_unless_empty", empty ? '' : ":#{placeholder}_with_where")
    clause.gsub!(":#{placeholder}_unless_empty", empty ? '' : ":#{placeholder}")

    clause.gsub!(":#{placeholder}_with_or"," #{replacement.strip.gsub(/^WHERE/,'')} OR ")
    clause.gsub!(":#{placeholder}_with_and"," #{replacement.strip.gsub(/^WHERE/,'')} AND ")
    clause.gsub!(":#{placeholder}_with_where","WHERE #{replacement.strip.gsub(/^WHERE/,'')} ")
    clause.gsub!(":#{placeholder}"," #{replacement.strip.gsub(/^WHERE/,'')} ")
  end

  def passes_sensitivity_check?
    if report_type == ReportType_SQL
      return true
    else
      if contains_sensitive_fields?
        # find the sensitive or identification fields
        # strip out the pipe if a one-to-many field
        # to_i is a quick way of doing that

        si = fields.select{|f| @setup.fields[f.to_s][:sensitive] || @setup.fields[f.to_s][:identification]}.collect{|i|@setup.fields[i.to_s]}
        # partition the fields into identification and non-identification
        s,i = si.partition{|f|f[:identification]}
        # if there are zero sensitive or zero identification fields, then you can proceed
        # for example:
        #   - you can query email and total_exercise_steps
        #   - you can query group_name and exercise_steps
        #   - you can query email
        #   - you can query exercise_steps
        #   - you CANNOT query email and exercise_steps

        return i.size==0 || s.size==0
      else
        return true
      end
    end
  end

  def contains_sensitive_fields?

    if report_type == ReportType_SQL
      return false
    else

      # is there a custom report setup file? if so use it, otherwise use default
      crsfn = "#{self.path}/#{ReportSetup.filename}"
      pth = File.exist?(crsfn) ? self.path : :default
      @setup ||= ReportSetup.find(:first)

      return !fields.detect{|f|@setup.fields[f.to_s][:sensitive] rescue false}.nil?
    end
  end

  private
  def make_sql
    raise 'This report contains both sensitive and identification fields.  It cannot be run.' unless passes_sensitivity_check?

    where = sql_where(filters)
    groups = sql_groups(fields).strip
    having = sql_having_from_hashes(filters[:hashes]||[]).strip

    statement = "\nselect #{'distinct' if groups.empty?} #{sql_fields(fields)}
    from FROM_TABLE_GOES_HERE #{sql_joins(fields,filters[:hashes])} 
    #{where}
    #{" group by #{groups}" unless groups.empty?}"
    statement << " HAVING #{having}" unless having.empty?

    statement.gsub("FROM_TABLE_GOES_HERE",'users')
  end

  def self.o2m(table_name)
    OneToManyTables.each do |x|
      # examples:
      #  'evaluations' == 'evaluations'
      #  /^evaluations/ =~ 'evaluations_with_comments'
      #  /evaluations$/ =~ 'with_comments_evaluations'
      return x if x == table_name || /^#{x}/ =~ table_name || /#{x}$/ =~ table_name
    end
    return nil
  end

  def o2m(table_name)
    return self.class.o2m(table_name)
  end

  def sql_fields(fields)
    return fields.collect{|f| tn=o2m(@setup.fields[f.to_s][:join]); tn ? @setup.fields[f.to_s][:sql_phrase].gsub(/#{tn}\./,"#{tn}#{f.to_s.split('|')[1]||1}.") : @setup.fields[f.to_s][:sql_phrase]}.join(',')
  end

  def sql_joins(fields,filters)
    # this array contains nested joins that have already been included
    # for example, if you include entries, you're implying trips (so that you can get back to user)
    # you only need to do so once
    nested_joins = []

    # first, join one-to-many tables required by the chosen fields
    o2m_sqls = []

    #fields.select{|f| o2m(@setup.fields[f][:join])}.sort{|x,y| @setup.joins.detect{|k,v|v[:alias]==@setup.fields[y][:join]}[1][:nest_level]<=>@setup.joins.detect{|k,v|v[:alias]==@setup.fields[x][:join]}[1][:nest_level]}.each do |f|
    fields.select{|f| o2m(@setup.fields[f.to_s][:join])}.each do |f|
      tn = o2m(@setup.fields[f.to_s][:join])
      n = f.to_s.split('|')[1]||'1'
      the_alias = "#{@setup.fields[f.to_s][:join]}"
      dyn_alias = "#{@setup.fields[f.to_s][:join]}#{n}"

      unless o2m_sqls.detect{|h|h[:dynamic_alias] == dyn_alias}
        j = @setup.joins.detect{|v|v.alias == @setup.fields[f][:join]}

        if j
          j.nest_level.times do |t|
            j = @setup.joins.detect{|v|v.alias==j.childof} if t > 0
            sql = j.sql
            dyn_alias = j.alias.gsub("#{tn}N","#{tn}#{n}").gsub("#{tn.singularize}N",n).gsub(/#{tn.pluralize}$/,"#{tn.pluralize}#{n}")
            unless nested_joins.include?(dyn_alias)
              if j.sql
                #raise "what is this?\nj: #{j.inspect}" unless sql
                o2m_sqls << {:nest_level=>j.nest_level,:dynamic_alias => dyn_alias, :sql => sql.to_s.gsub("#{tn}N","#{tn}#{n}").gsub("#{tn.singularize}N",n)}
                nested_joins << dyn_alias
              end
            end
          end
        end

      end
    end

    # second, join one-to-many tables required by the chosen filters
    filters.select{|f| o2m(@setup.fields[f[:field].to_s][:join])}.each do |f|
      tn = o2m(@setup.fields[f[:field].to_s][:join])
      n = f[:field].to_s.split('|')[1]||'1'
      the_alias = "#{@setup.fields[f[:field].to_s][:join]}"
      dyn_alias = "#{@setup.fields[f[:field].to_s][:join]}#{n}"
      unless o2m_sqls.detect{|h|h[:dynamic_alias]==dyn_alias}
        # make sure that this nested join hasn't already been added by a field
        unless  nested_joins.include?(dyn_alias)
          j = @setup.joins.detect{|k,v|v[:alias]==@setup.fields[f[:field].to_s][:join]}[1]
          o2m_sqls << {:nest_level=>j[:nest_level],:dynamic_alias => dyn_alias, :sql => j[:sql].gsub("#{tn}N","#{tn}#{n}").gsub("#{tn.singularize}N",n)}
          nested_joins << dyn_alias # add it so that the code below doesn't doubly add it
          j[:nest_level].times do |t|
            j = @setup.joins.detect{|k,v|v[:alias]==j[:childof]}[1] if t > 0
            sql = j[:sql]
            dyn_alias = j[:alias].gsub("#{tn}N","#{tn}#{n}").gsub("#{tn.singularize}N",n).gsub(/#{tn.pluralize}$/,"#{tn.pluralize}#{n}")
            unless nested_joins.include?(dyn_alias)
              o2m_sqls << {:nest_level=>j[:nest_level],:dynamic_alias => dyn_alias, :sql => sql.gsub("#{tn}N","#{tn}#{n}").gsub("#{tn.singularize}N",n)}
              nested_joins << dyn_alias
            end
          end
        end
      end
    end

    # need to sort by nest level because nested joins may be out of order
    o2m_sqls.sort!{|x,y|x[:nest_level]<=>y[:nest_level]}

    # o2m_joins is the raw sql for all of the one-to-many joins required by fields and filters
    o2m_joins = o2m_sqls.collect{|h|h[:sql]}

    # now, look for anything that is not a one-to-many (like profile) in the fields and filters
    aliases = fields.collect{|f| @setup.fields[f.to_s][:join]}.delete_if{|a|a=='users'||o2m(a)||nested_joins.include?(a)}
    aliases << filters.collect {|filter| @setup.fields[filter[:field].to_s][:join]}.delete_if{|j|o2m(j)}

    # kludge?
    # aliases << "trips" if self.filters[:strings].select{|s|s.include?'trips.'}.first
    aliases << "promotions" if self.filters[:strings].select{|s|s.include?'promotions.'}.first
    aliases << "organizations" if self.filters[:strings].select{|s|s.include?'organizations.'}.first

    aliases.flatten!

    # do a uniq on aliases.
    # if you select/filter > 1 field from a particular alias, you only need to join it once
    # otherwise you join the same table n times where n is the number of fields and filters
    # and that is either redundant at best and a MySQL error at worst
    aliases.sort!{|x,y| (@setup.joins.detect{|k,v|v[:alias]==x}[1][:nest_level].abs rescue 0) <=> (@setup.joins.detect{|k,v|v[:alias]==y}[1][:nest_level].abs rescue 1)}
    aliases.uniq.each do |a| #{|a|@setup.joins.detect{|k,v|v[:alias]==a}[1][:sql] rescue nil}.delete_if{|a|a.nil?}
      # puts @setup.joins.inspect
      join = @setup.joins.detect{|j|j.alias == a}
      if join
        sql = join.sql
        if join.childof.is_a?(Array)
          # when childof is an array, that means that the table has many parents (e.g. reseller, org, promo, user, trip all have many stats)
          # figure out what table to use
          tbl_i = fields.detect{|f| join.childof.include?(@setup.fields[f.to_s][:join])}
          tbl_s = tbl_i ? @setup.fields[tbl_i.to_s][:join] : 'users'
          sql = sql.gsub(/SINGULAR/,tbl_s.singularize).gsub(/PLURAL/,tbl_s.pluralize)
          raise [tbl_i, tbl_s, sql].inspect if join.alias == 'promotion_locations'
        end
        o2m_joins << sql unless nested_joins.include?(join.alias)
        # be aware of negative numbers for nest_level.  nest_level refers to the table's degree of separation from the table 'users'
        # trips is 1 because it is beneath users, promotions is -1 because it is above users.  get it?
        if (-998..998).include?(join.nest_level) && !nested_joins.include?(join.alias)
          j = @setup.joins.detect{|_j|_j.alias == join.alias}
          (j.nest_level.abs-1).times do |t|

            j = @setup.joins.detect{|_j| _j.alias == (j.nest_level > 0 ? j.childof : j.parentof)}

            unless nested_joins.include?(j.alias) || aliases.include?(j.alias)
              sql = j.sql
              o2m_joins.insert(o2m_joins.size-1-t,sql)
              nested_joins << j.alias
            end
          end
        end
      end
    end
    return o2m_joins.join(' ')
  end

  def sql_where(filters)
    filters[:special]||={:reseller_id=>nil,:organization_id=>nil,:promotion_id=>nil,:promotion_trip_id=>nil,:location=>nil,:reported_on_min=>nil,:reported_on_max=>nil}
    where = ''
    filters[:strings] = special_conditions(filters[:special])
    where_strings = filters[:strings].join(' AND ').strip
    where_strings = " (#{where_strings}) " unless where_strings.empty?
    where_hashes = sql_where_from_hashes(filters[:hashes]||[]).strip
    where = ""
    unless where_strings.empty? && where_hashes.empty?
      where << "WHERE "
      where << "(#{where_strings}) #{' AND ' unless where_hashes.empty?}" unless where_strings.empty?
      where << "#{where_hashes} "
    end

    return where
  end

  def special_conditions(special)
    r,o,p,t = special[:reseller_id], special[:organization_id], special[:promotion_id], special[:promotion_trip_id]
    sc = []
    sc << "users.reseller_id = #{special[:reseller_id]}" unless r.nil? || r=="*"
    sc << "users.organization_id = #{o}" unless o.nil? || o=="*"
    sc << "users.promotion_id = #{p}" unless p.nil? || p=="*"

    if special[:reported_on_min] && special[:reported_on_max]
      i,a = special[:reported_on_min], special[:reported_on_max]
      sc << "
            (
             users.created_at between '#{i.strftime('%Y-%m-%d')}' and '#{a.strftime('%Y-%m-%d')}'
            )
           "
      sc << "entries.recorded_on between '#{i.strftime('%Y-%m-%d')}' and '#{a.strftime('%Y-%m-%d')}'" if is_joined('entries')
    end

    lj =
    if self.report_type == ReportType_SQL
      :users
    else
      :users
    end

    sc << "#{lj}.top_level_location_id = '#{special[:top_level_location]}'" if special[:top_level_location]
    sc << "#{lj}.location_id = '#{special[:location]}'" if special[:location]

    return sc
  end

  def is_joined(lookfor)
    a = []
    
    a << fields.collect{|f| @setup.fields[f.to_s][:join]}

    # Rails.logger.info "\n\nSetUp Fields: #{@setup.fields.inspect}\n\n"
    # Rails.logger.info "\n\nReport Fields: #{fields.inspect}\n\n"
    # a << fields.collect{|f| Rails.logger.info "\n\n#{f}\n\n"; @setup.fields[f.to_s][:join]}

    a << filters[:hashes].collect{|f| @setup.fields[f[:field].to_s][:join]}
    a.flatten!
    more_a = []

    # ignore fields where join is users
    # because that it not a join
    # because users is the FROM clause
    a.delete_if{|x| x == "users"}

    a.each do |aliaz|
      j = @setup.joins.detect{|k| k.alias == aliaz}
      if j
        j.nest_level.times do |t|

          if j.childof
            j = @setup.joins.detect{|k| j.childof.is_a?(Array) ? j.childof.include?(k.alias) : k.alias == j.childof} if t > 0
            more_a << j.alias
          end
        end
      end
    end

    a << more_a
    a.flatten!
    return a.include?(lookfor)
  end

  # returns a WHERE clause for non-aggregate fields
  def sql_where_from_hashes(filters)
    clause=filters.select{|f|!@setup.fields[f[:field].to_s][:aggregate]}.collect{|f| tn=o2m(@setup.fields[f[:field].to_s][:join]); " #{strip_aliases(tn ? @setup.fields[f[:field].to_s][:sql_phrase].gsub(/#{tn}\./,"#{tn}#{f[:field].to_s.split('|')[1]||1}.").gsub(/#{tn.singularize.titleize}/,"#{(f[:field].to_s.split('|')[1]||1).to_i.ordinalize} #{tn.singularize.titleize}") : @setup.fields[f[:field].to_s][:sql_phrase])} #{f[:sign]} ? #{'AND ?' if f[:sign]=='between'}"}.join(" AND ")
    values=filters.select{|f|!@setup.fields[f[:field].to_s][:aggregate]}.collect{|f| f[:sign] == 'between' ? f[:value] : f[:value].to_s.downcase == 'true' ? true : f[:value].to_s.downcase == 'false' ? false : "#{f[:value]}#{'%' if f[:sign]=='like'}"}
    return clause.nil? || clause.empty? ? "" : " #{User.send(:sanitize_conditions,[clause,values].flatten)} "
  end

  # returns a HAVING clause for aggregate fields which may not appear in a WHERE clause
  def sql_having_from_hashes(filters)
    clause = []
    values = []

    aggregate_fields(filters).each do |field|
      single_clause = ""
      tn = o2m(@setup.fields[field[:field].to_s][:join])

      if tn
        single_clause = @setup.fields[field[:field].to_s][:sql_phrase].split("`").first.gsub(/#{tn}\./,"#{tn}#{field[:field].to_s.split('|')[1]||1}.")
        single_clause = single_clause.gsub(/#{tn.singularize.titleize}/,"#{(field[:field].to_s.split('|')[1]||1).to_i.ordinalize} #{tn.singularize.titleize}")
      else
        single_clause = @setup.fields[field[:field].to_s][:sql_phrase].split("`").first
      end

      single_clause += " #{field[:sign]} ? #{'AND ?' if field[:sign] == 'between'}"

      clause << single_clause

      if field[:sign] == 'between'
        values << field[:value]
      else
        if field[:value].to_s.downcase == 'true'
          values << true
        elsif field[:value].to_s.downcase == 'false'
          values << false
        elsif field[:sign] == 'like'
          values << "#{field[:value]}%"
        elsif field[:value].to_i.to_s == field[:value]
          values << field[:value].to_i
        else
          values << field[:value]
        end
      end
    end

    return clause.empty? ? "" : " #{User.send(:sanitize_conditions,[clause.join(' AND '),values].flatten)} "
  end

  def aggregate_fields(filters)
    return filters.select{|f| @setup.fields[f[:field].to_s][:aggregate]}
  end

  def non_aggregate_fields(filters)
    return filters.select{|f|!@setup.fields[f[:field].to_s][:aggregate]}
  end

  def sql_groups(fields)
    g = ''
    if fields.detect{|f|@setup.fields[f.to_s][:aggregate]}
      non_aggregate_fields = fields.select{|f| !@setup.fields[f.to_s][:aggregate] }
      g = strip_aliases(non_aggregate_fields.collect{|f|tn=o2m(@setup.fields[f.to_s][:join]); tn ? @setup.fields[f.to_s][:sql_phrase].gsub(/#{tn}\./,"#{tn}#{f.to_s.split('|')[1]||1}.").gsub(/#{tn.singularize.titleize}/,"#{(f.to_s.split('|')[1]||1).to_i.ordinalize} #{tn.singularize.titleize}") : @setup.fields[f.to_s][:sql_phrase]}.join(', '))
    end
    return g
  end

  def strip_aliases(s)
    if s.include?('`')
      # if the group by looks like stats.first_name `First Name`
      # then strip out everything between ` and ` including `
      # so that group by looks like stats.first_name
      new_s = ''
      keep = true
      s.each_char {|c|keep=!keep if c=='`'; new_s<<c if keep && c!='`';}
      s=new_s
    end
    return s
  end
end