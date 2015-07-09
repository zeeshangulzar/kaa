# copied from healthtrails/lib/activities_for_reports.rb
module BehaviorsForReports
  def self.add_behavior_joins(joins,promotion)
    model = joins.detect{|j|j.alias=='entry_behaviors'}.dup

    behaviors = promotion.behaviors
    behaviors.each do |behavior|
      k = "eb_#{behavior.id}"
      ak = "b_#{behavior.id}"
      new_join = model.dup
      new_join.alias = k
      new_join.sql = "left join entry_behaviors #{k} on (#{k}.entry_id = entries.id and #{k}.behavior_id = #{behavior.id}) \n left join behaviors #{ak} on (#{k}.behavior_id = #{ak}.id)" 
      joins << new_join
    end
    joins
  end

  def self.add_behavior_fields(fields,promotion)
    model = {
      :visible => true,
      :role => User::Role[:coordinator],
      :display_name => nil,
      :identification => false,
      :sql_phrase => nil,
      :aggregate => true,
      :sensitive => false,
      :filterable => true,
      :sequence => nil,
      :join => nil
    }
   
    behaviors = promotion.behaviors

    behaviors.each do |behavior|
      next if behavior.name.downcase =~ /weight/

      jk = "eb_#{behavior.id}"
      jak = "b_#{behavior.id}"
        if behavior.cap_value.to_i>0
          # if the value is under the cap, show the value; otherwise show what the capped value would be
          if behavior.cap_value.to_i>9999
            cap_data_type = 'DECIMAL(15,5)'
          elsif behavior.cap_value.to_i>99
            cap_data_type = 'DECIMAL(11,5)'
          else
            cap_data_type = 'DECIMAL(7,5)'
          end
          cap_function = "LEAST(CAST(#{jk}.value AS #{cap_data_type}),#{jak}.cap_value)"

          k = "entry_behaviors_sum_cap:#{behavior.id}"
          fields[k] = model.dup
          fields[k][:display_name] = "#{behavior.name.titleize} - Total (Capped)"
          fields[k][:sql_phrase] = "coalesce(sum(#{cap_function}),0) `#{behavior.name.titleize} - Total (Capped)`"
          fields[k][:sequence] = fields.size
          fields[k][:join] = jk
          fields[k][:category] = 'Activity Fields' 

          k = "entry_behaviors_avg_cap:#{behavior.id}"
          fields[k] = model.dup
          fields[k][:display_name] = "#{behavior.name.titleize} - Average (Capped)"
          fields[k][:sql_phrase] = "coalesce(round(sum(#{cap_function}) / count(distinct entries.id),1),0) `#{behavior.name.titleize} - Average (Capped)`"
          fields[k][:sequence] = fields.size
          fields[k][:join] = jk
          fields[k][:category] = 'Activity Fields' 
        end

        k = "entry_behaviors_sum:#{behavior.id}"
        fields[k] = model.dup
        fields[k][:display_name] = "#{behavior.name.titleize} - Total (Actual)"
        fields[k][:sql_phrase] = "coalesce(sum(#{jk}.value),0) `#{behavior.name.titleize} - Total (Actual)`"
        fields[k][:sequence] = fields.size
        fields[k][:join] = jk
        fields[k][:category] = 'Activity Fields' 

        k = "entry_behaviors_avg:#{behavior.id}"
        fields[k] = model.dup
        fields[k][:display_name] = "#{behavior.name.titleize} - Average (Actual)"
        fields[k][:sql_phrase] = "coalesce(round(sum(#{jk}.value) / count(distinct entries.id),1),0) `#{behavior.name.titleize} - Average (Actual)`"
        fields[k][:sequence] = fields.size
        fields[k][:join] = jk
        fields[k][:category] = 'Activity Fields' 

#        if behavior.type_of_prompt == Activity::PromptTypes[:label]
#          k = "entry_behaviors_actual:#{behavior.id}"
#          fields[k] = model.dup
#          fields[k][:display_name] = "#{behavior.name.titleize}"
#          fields[k][:aggregate] = false 
#          fields[k][:sql_phrase] = "coalesce(cast(#{jk}.value as signed),0) `#{behavior.name.titleize}`"
#          fields[k][:sequence] = fields.size
#          fields[k][:join] = jk
#          fields[k][:category] = 'Activity Fields' 
#        end

      k = "entry_behaviors_times:#{behavior.id}"
      fields[k] = model.dup
      fields[k][:display_name] = "#{behavior.name.titleize} - Times Recorded"
      fields[k][:sql_phrase] = "coalesce(sum(if((#{jk}.value > 0),1,0)),0) `#{behavior.name.titleize} - Times Recorded`"
      fields[k][:sequence] = fields.size
      fields[k][:join] = jk
      fields[k][:category] = 'Activity Fields' 
    end
    
    fields
  end
end

Report::Categories.insert(1,'Activity Fields')
