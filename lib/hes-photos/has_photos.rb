module HesPhotos
  # Methods for have an ActiveRecord model to own photos
  module HasPhotos
    def has_photos
      self.send(:define_method, :photos) do
        Photo.where(:photoable_type => self.class.to_s, :photoable_id => self.id).order("created_at DESC")
      end
      
      # this deletes all the photoable's photos when the object is deleted
      self.send(:define_method, :destroy) do
        Photo.where(:photoable_type => self.class.to_s, :photoable_id => self.id).destroy_all
        super
      end
    end
  end
end
