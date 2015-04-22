class CreateCompetitions < ActiveRecord::Migration
  def change
    create_table :competitions do |t|
      t.references    :promotion
      t.string        :name
      t.date          :enrollment_starts_on
      t.date          :enrollment_ends_on
      t.date          :competition_starts_on
      t.date          :competition_ends_on
      t.integer       :freeze_team_scores,            :default => 1
      t.integer       :team_size_min,                 :default => 5
      t.integer       :team_size_max,                 :default => nil
      t.boolean       :active,                        :default => true
      t.timestamps
    end
  end
end
