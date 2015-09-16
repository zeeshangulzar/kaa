class ReportSetup < HesReportsYaml::HasYamlContent::YamlContentBase
  attr_accessor :joins
  
  BuiltInJoins = {1=>{:alias=>'users',:sql=>''},2=>{:alias=>'evaluations',:sql=>''}} unless defined?(BuiltInJoins)
  
  def initialize(a={})
    super
    self.attributes = a
  end

  def joins
    return @_joins || get_joins
  end

  def joins=(_joins)
    @_joins = _joins
  end

  def get_joins
    @_joins = ReportJoinArray.new
    @joins.each_pair do |k, v|
      @_joins << ReportJoin.new(v.merge(:id => k.to_i))
    end
    return @_joins
  end
  private :get_joins

  def update_join(join)
    @joins[join.id.to_s] = join.symbolize
    save
  end
  
  def add_join(join)
    get_joins if @_joins.nil?
    join.id = @_joins.collect{|x| x.id}.sort{|x, y| x.to_i <=> y.to_i}.last + 1
    @joins[join.id.to_s] = join.symbolize  
    save
  end
  
  def remove_join(join)
    @joins.delete(join.id.to_s)
    save
  end
  
  def report_fields
    return @_fields || get_fields
  end
  
  def fields
    return @fields
  end
  
  def fields=(_fields)
    @fields = _fields
    @_fields = nil #will lazy initialize next time needed
  end
  
  def get_fields
    @_fields = ReportFieldArray.new
    @fields.each_pair do |k, v|
      @_fields << ReportField.new(v.merge(:id => k.to_i))
    end
    return @_fields
  end
  private :get_fields
  
  def update_field(field)
    @fields[field.id.to_s] = field.symbolize
    save
  end
  
  def add_field(field)
    field.id = @_fields.collect{|x| x.id}.sort{|x, y| x.to_i <=> y.to_i}.last + 1
    @fields[field.id.to_s] = field.symbolize  
    save
  end
  
  def remove_field(field)
    @fields.delete(field.id.to_s)
    save
  end
    
  # Method to override the default YAML settings
  def to_yaml_properties
    return ['@id','@fields','@joins']
  end
  
  def attributes
    return { :fields => fields.symbolize, :joins => joins }
  end
  
  def attributes=(attributes)
    @fields = attributes[:fields]||{}
    @joins = attributes[:joins]||{}
    @joins.merge BuiltInJoins
  end
  
  def update_attributes(attributes)
    self.attributes = attributes
    save
  end

  def self.typeof
    return ReportSetup
  end
  
  def all_column_names
    internal_joins = BuiltInJoins.keys.collect{|k| BuiltInJoins[k][:alias]}
    other_joins = []
    self.joins.each_value{|v| other_joins << "#{v[:sql]}" unless internal_joins.include?(v[:alias])}
    all_fields_sql = "select * from users left join evaluations ev on (ev.user_id = users.id) #{other_joins.join(' ')} where 1=2"
    r = ActiveRecord::Base.connection.execute(all_fields_sql)
    return r.fetch_fields.collect{|f|f.name}
  end
  
  def add_other_promotion_specific_fields(fields,promotion)

    # # for minute and step fields, you have to see how the promotion's configured to seemingly hide one and show the other
    # # if the user decides, then you have to add both by dup'ing the field
    # new_fields = {}
    # fields.each_key do |k|
    #   if fields[k][:display_name] =~ /WHAT_TO_TRACK/
    #     wtt = []
    #     wtt << ['MINUTES','Minutes'] if promotion.track_minutes?
    #     wtt << ['STEPS','Steps'] if promotion.track_steps?
    #     wtt.each do |pair|
    #       nk="#{k}#{pair.first}"
    #       new_fields[nk]=fields[k].dup
    #       new_fields[nk][:display_name]= new_fields[nk][:display_name].gsub(/WHAT_TO_TRACK/,pair.last)
    #       new_fields[nk][:sql_phrase]= new_fields[nk][:sql_phrase].gsub(/WHAT_TO_TRACK/,pair.last)
    #     end
    #     fields.delete(k)
    #   end
    # end
    # fields.merge!(new_fields)

    # if promotion.requires_eligibility?
    #   fields.each_key do |k|
    #     if fields[k][:join] == 'eligibilities'
    #       fields[k][:visible] = true
    #       fields[k][:display_name] = promotion.detail.eligibility_label.to_s.empty? ? 'Eligibility Id' : promotion.detail.eligibility_label
    #       fields[k][:sql_phrase] = "eligibilities.identifier `#{fields[k][:display_name]}`"
    #     end
    #   end
    # end

    location_labels = promotion.location_labels
    if promotion.flags[:is_location_displayed]
      fields.each_key do |k|
        if fields[k][:display_name]=~/Top Level Location/
          fields[k][:visible] = true if location_labels.size > 1
          fields[k][:display_name] = fields[k][:display_name].gsub(/Top Level Location/,location_labels.first)
          fields[k][:sql_phrase] = fields[k][:sql_phrase].gsub(/Top Level Location/,location_labels.first)
        elsif fields[k][:display_name]=~/Location/
          fields[k][:visible] = true
          fields[k][:display_name] = fields[k][:display_name].gsub(/Location/,location_labels.last)
          fields[k][:sql_phrase] = fields[k][:sql_phrase].gsub(/Location/,location_labels.last)
        end
      end
    end
    # if promotion.organization.is_sso_enabled
    #   fields.each_key do |k|
    #       if fields[k][:sql_phrase]=~/sso_identifier/
    #         fields[k][:visible] = true
    #         fields[k][:display_name] = promotion.organization.sso_label.to_s.empty? ? 'SSO Identifier' : promotion.organization.sso_label
    #         fields[k][:sql_phrase] = "users.sso_identifier `#{fields[k][:display_name]}`"
    #       end
    #   end
    # end
    # if promotion.flags[:is_age_displayed]
    #   fields.each_key do |k|
    #       if fields[k][:sql_phrase]=~/born_on/
    #         fields[k][:visible] = true
    #       end
    #   end
    # end
    # if promotion.flags[:is_address_displayed]
    #   fields.each_key do |k|
    #       if fields[k][:join]=='addresses'
    #         fields[k][:visible] = true
    #       end
    #   end
    return fields
  end
  
  def visible_fields(role, promotion)
    roles = role==HesAuthorization::AuthRole.auth_roles[:master] ? [HesAuthorization::AuthRole.auth_roles[:master],HesAuthorization::AuthRole.auth_roles[:reseller],HesAuthorization::AuthRole.auth_roles[:coordinator]] :
            role==HesAuthorization::AuthRole.auth_roles[:reseller] ? [HesAuthorization::AuthRole.auth_roles[:reseller],HesAuthorization::AuthRole.auth_roles[:coordinator]] :
            [HesAuthorization::AuthRole.auth_roles[:coordinator]]
    f = add_other_promotion_specific_fields(@fields, promotion)
    o2m = add_one_to_many_fields(f.reject {|k,v| !roles.include?(v[:role]) || !v[:visible]}, promotion)
    add_custom_prompts(o2m, promotion)
    # see lib/behaviors_for_reports.rb
    BehaviorsForReports.add_behavior_joins(joins,promotion)
    BehaviorsForReports.add_behavior_fields(o2m,promotion)
    return add_other_promotion_specific_fields(o2m, promotion)
  end
  
  def filterable_fields(role,promotion)
    return visible_fields(role,promotion).reject{|k,v|!v[:filterable]}
  end

  #def categories
    #@categories||=Report::Categories.dup
    #@categories
    #fields.collect{
  #end
  
  def add_one_to_many_fields(fields, promotion)
    # for each one-to-many relationship, add it to new_fields
    # evaluations becomes evaluations1, evaluations2, etc
    # sorry of the vagueness..  this used to be evaluations only, now it is any o2m off of promotion
    new_fields = {}
    fields.each_pair do |k,v|
      o2m = Report.o2m(v[:join])
      if o2m
        promotion.send(o2m).reload unless promotion.send(o2m).loaded?
        fields.delete(k)

        if o2m == 'evaluations'
          promotion.evaluation_definitions.each_with_index do |eval_def, index|
            newk = "#{k}|#{eval_def.sequence}"
            new_fields[newk] = v.dup
            new_fields[newk][:sequence] += (index+1)/10.0  # heh heh heh sort trick
            new_fields[newk][:sql_phrase] = new_fields[newk][:sql_phrase].gsub(/#{o2m}\./,"#{o2m}#{eval_def.sequence}.").gsub(/Nth/,"#{(index+1).ordinalize}")

            if index == 0
              new_fields[newk][:category] = "Registration Fields"
            else
              new_fields[newk][:category] = (Report::Categories.detect{|x|x.downcase.include? o2m.singularize}||'Uncategorized').gsub(/ N /," #{index} ")
            end
          end
        # elsif o2m == 'locations'
        #   Rails.logger.warn "\n\n\nLOCATION LABELS:\n#{promotion.location_labels_as_array.inspect}\n\n\n"
        #   promotion.location_labels_as_array.each_with_index do |location_label, index|
        #     newk = "#{k}|#{index + 1}"
        #     new_fields[newk] = v.dup
        #     new_fields[newk][:sequence] += (index+1)/10.0  # heh heh heh sort trick
        #     new_fields[newk][:sql_phrase] = new_fields[newk][:sql_phrase].gsub(/#{o2m}\./, "#{o2m}#{index+1}.").gsub(/LN/, "#{location_label}")
        #     new_fields[newk][:display_name] = location_label
        #     new_fields[newk][:category] = 'Participant Fields'
        #     new_fields[newk][:join] = "locations#{index+1}"
        #   end
        elsif o2m == 'competitions'
          promotion.competitions.each_with_index do |competition, index|
            newk = "#{k}|#{index + 1}"
            new_fields[newk] = v.dup
            new_fields[newk][:sequence] += (index+1)/10.0  # heh heh heh sort trick
            new_fields[newk][:sql_phrase] = new_fields[newk][:sql_phrase].gsub(/#{o2m}\./,"#{o2m}#{index+1}.").gsub(/Nth/,"#{(index+1).ordinalize}")
            new_fields[newk][:category] = (Report::Categories.detect{|x|x.downcase.include? o2m.singularize}||'Uncategorized').gsub(/ N /," #{index + 1} ")
          end
        end
      end
    end
    return fields.merge(new_fields)
  end

  def add_custom_prompts(fields, promotion)
    # should we assume that all of these are identification and/or sensitive?
    # should we define them as such on the edit_custom_prompt screen?
    
    model = {
      :visible => true,
      :role => HesAuthorization::AuthRole.auth_roles[:coordinator],
      :display_name => nil,
      :identification => false,
      :sql_phrase => nil,
      :aggregate => false,
      :sensitive => false,
      :filterable => false,
      :sequence => nil,
      :join => nil
    }
   
    cps = promotion.custom_prompts.find(:all, :include => [:udf_def])
    
    cps.each do |cp|
      if cp.is_active && ![CustomPrompt::HEADER, CustomPrompt::PAGEBREAK].include?(cp.type_of_prompt)
        promotion.evaluation_definitions.each_with_index do |pev, index|
          k = "evaluations_udfs:#{cp.id}|#{pev.id}"
          fields[k] = model.dup
          fields[k][:display_name] = "#{cp.short_label}*"
          fields[k][:sql_phrase] = "evaluations#{pev.id}_udfs.#{cp.udf_def.cfn} `#{cp.short_label} At "
          fields[k][:sql_phrase] = fields[k][:sql_phrase] + (pev.sequence ? "#{pev.sequence.ordinalize} Evaluation`" : 'Registration`')
          fields[k][:sequence] = fields.size
          fields[k][:join] = 'evaluationsN_udfs'

          if index == 0
            fields[k][:category] = "Registration Fields"
          else
            fields[k][:category] = Report::Categories.detect{|x|x.downcase.include?'evaluation'}.gsub(/ N /," #{index} ")
          end
        end
      end
    end
    return fields
  end

end
