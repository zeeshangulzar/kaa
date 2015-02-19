class ChangePromotionLogo < ActiveRecord::Migration
  def up
    rename_column :promotions, :logo_url, :logo
  end

  def down
    rename_column :promotions, :logo, :logo_url
  end
end
