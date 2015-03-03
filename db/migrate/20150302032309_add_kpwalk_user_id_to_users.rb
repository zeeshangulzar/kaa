class AddKpwalkUserIdToUsers < ActiveRecord::Migration
  def change
    add_column :users,:kpwalk_user_id,:integer
    add_column :users,:kpwalk_level,:string
    add_column :users,:kpwalk_total_minutes,:integer
    add_column :users,:kpwalk_total_stars,:integer
    add_index :users,[:promotion_id,:kpwalk_user_id],:name=>:by_promotion_id_and_kpwalk_user_id_unique,:unique=>true
  end
end
