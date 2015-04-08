class KpVerified < ActiveRecord::Migration
  def self.up
    execute "create view kp_verified as select * from kpwalks#{'_development' if Rails.env=='development'}.kp_verified"
    #20110902193419
    execute "create table kp_verification (user_id int,create_date date)"
    execute "create index by_user_id on kp_verification(user_id)"
    #execute "grant all on kp_verification to 'kpwalks'@'%'"
  end

  def self.down
    execute "drop view kp_verified"
    execute "drop table kp_verification"
  end
end
