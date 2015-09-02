class Tip < ContentModel
  column :day, :integer
  column :title, :string, :limit => 500
  column :summary, :text
  column :content, :text
  column :full_image, :string
  column :small_image, :string
  column :email_image, :string
  column :email_subject, :string
  column :email_image_caption, :text

  customize_by :promotion

  scope :asc, :order => "day ASC"

  scope :desc, :order => "day DESC"
  
  markdown :summary, :content

  mount_uploader :full_image, TipFullImageUploader
  mount_uploader :small_image, TipSmallImageUploader
  mount_uploader :email_image, TipEmailImageUploader

  acts_as_likeable :label => "Favorite"
  acts_as_shareable
  has_wall

  SkipDays = [0,6]

  # this will answer "what tip do i display today?"
  def self.get_day_number_from_date(date=Date.today,u=nil)
    skipdays = SkipDays
    @@cached_day_numbers||={}

    return @@cached_day_numbers[date] if @@cached_day_numbers[date]
    #figure out january 1 of the year of the date passed in
    firstDayOfYear = Date.parse("1/1/#{date.year}")
    firstDayOfYear +=1 while skipdays.include?(firstDayOfYear.wday)

    # return the December 31 tip from last year if you aren't supposed to see the first tip yet
    return get_day_number_from_date(Date.parse("12/31/#{date.year-1}")) if date < firstDayOfYear

    daysToCheck = (date - firstDayOfYear).to_i

    #figure out how many weekdays there are up until that date
    dayNumber = 1
    daysToCheck.times do |t|
      dayNumber += 1 unless skipdays.include?((firstDayOfYear+t+1).wday)
    end
    @@cached_day_numbers[date] = dayNumber
    return dayNumber
  end

  def self.get_weekdays_in_year(year = Date.today.year)
    range = (Date.parse(year.to_s + "-01-01")..Date.parse(year.to_s + "-12-31")).to_a
    return range.select{|d|(1..5).include?(d.wday)}.size
  end

end
