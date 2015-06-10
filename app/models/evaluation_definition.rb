# Models a evaluation definition that is used to create an evaluation
class EvaluationDefinition < ApplicationModel

  scope :active, where("start_date <= '#{Date.today}' AND end_date >= '#{Date.today}'").order("start_date ASC")

  scope :active_with_user, lambda{ |user|
    days = user.promotion.current_date - user.profile.started_on rescue 0
    where("(start_date <= '#{user.promotion.current_date}' AND end_date >= '#{user.promotion.current_date}') OR days_from_start <= #{days}").order("start_date ASC")
  }

  attr_accessible *column_names
  attr_privacy :name, :days_from_start, :message, :visible_questions, :start_date, :end_date, :public

  belongs_to :promotion

  has_many :evaluations

  many_to_many :with => :custom_prompt, :primary => :evaluation_definition

  after_save :promotion_updated

  def promotion_updated
    publish = false
    columns_to_check = ['start_date', 'end_date']
    columns_to_check.each{|column|
      if self.send(column) != self.send(column + "_was")
        publish = true
        break
      end
    }
    if publish
      p = self.promotion.reload
      $redis.publish('promotionUpdated', p.as_json.to_json)
    end
  end

  # Overrides serializable_hash so that questions and custom prompts can be included
  def serializable_hash(options = {})
    hash = super(options)

    hash["questions"] = []

    # Include the default questions.
    EvaluationQuestion.all.each do |question|
      hash["questions"] << question.serializable_hash
    end

    # Include any custom prompts it's promotion might have.
    promotion.custom_prompts.each do |custom_prompt|
      hash["questions"] << custom_prompt.serializable_hash.merge({"name" => custom_prompt.name, "type_of_prompt" => custom_prompt.type_of_prompt.upcase}) #if self.send("is_#{custom_prompt.short_label.downcase..gsub(' ', '_')}_displayed?")
    end

    hash
  end

  # TODO: figure out what this does and why the hell nothing defined after it sticks to the model...
  maintain_sequence

end