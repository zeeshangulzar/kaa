class GroupUsersController < ApplicationController
  authorize :all, :user

  def index
    group = Group.find(params[:group_id]) rescue nil
    if !group
      return HESResponder("Group", "NOT_FOUND")
    elsif group.owner.id != @user.id && !@user.master?
      return HESReponder("You may not view this group.", "DENIED")
    else
      return HESResponder(user.groups)
    end
  end

  def show
    group_user = GroupUser.find(params[:id]) rescue nil
    if !group_user
      return HESResponder("Group User", "NOT_FOUND")
    elsif group.owner.id != @user.id && !@user.master?
      return HESReponder("You may not view this group user.", "DENIED")
    else
      return HESResponder(group_user)
    end
  end

  def create
    if params[:group_id].nil? || params[:user_id].nil?
      return HESResponder('Must include group and user id.', "ERROR")
    end
    group = Group.find(params[:group_id]) rescue nil
    user = User.find(params[:user_id]) rescue nil
    if !group
      return HESResponder("Group", "NOT_FOUND")
    elsif !user
      return HESResponder("User", "NOT_FOUND")
    end
    if group.owner.id != @user.id && !@user.master?
      return HESReponder("You may not edit this group.", "DENIED")
    end
    if !group.owner.friends.include?(user)
      return HESReponder("You are not friends with user.", "DENIED")
    end
    group_user = group.users.build(:user_id => user.id)
    GroupUser.transaction do
      group_user.save!
    end
    if !group_user.valid?
      return HESResponder(group_user.errors.full_messages, "ERROR")
    end
    return HESResponder(group_user)
  end
  
  def update
    group_user = GroupUser.find(params[:id]) rescue nil
    group = group_user.group rescue nil
    user = User.find(params[:group][:user_id]) rescue nil
    if !group
      return HESResponder("Group", "NOT_FOUND")
    elsif !group_user
      return HESResponder("Group User", "NOT_FOUND")
    elsif !user
      return HESResponder("User", "NOT_FOUND")
    end
    if group.owner.id != @user.id && !@user.master?
      return HESReponder("You may not edit this group.", "DENIED")
    end
    if !group.owner.friends.include?(user)
      return HESReponder("You are not friends with user.", "DENIED")
    end
    GroupUser.transaction do
      group_user.update_attributes(params[:group_user])
    end
    if !group_user.valid?
      return HESResponder(group_user.errors.full_messages, "ERROR")
    end
    return HESResponder(group_user)
  end
  
  def destroy
    group_user = GroupUser.find(params[:id]) rescue nil
    if !group_user
      return HESResponder("Group User", "NOT_FOUND")
    elsif (group_user.group.owner == @user || @user.master?) && group_user.destroy
      return HESResponder(group_user)
    else
      return HESResponder("Error deleting.", "ERROR")
    end
  end

end
