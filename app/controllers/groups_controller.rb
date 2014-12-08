class GroupsController < ApplicationController
  authorize :all, :user

  def index
    user = User.find(params[:user_id]) rescue nil
    user = user.nil? ? @user : user
    if user != @user && !@user.master?
      return HESReponder("You may not view user's groups.", "DENIED")
    else
      return HESResponder(user.groups)
    end
  end

  # Get a group
  #
  # @url [GET] /groups/1
  # @param [Integer] id The id of the group
  # @return [Group] Group that matches the id
  #
  # [URL] /groups/:id [GET]
  #  [200 OK] Successfully retrieved Group
  def show
    group = Group.find(params[:id]) rescue nil
    if !group
      return HESResponder("Group", "NOT_FOUND")
    elsif group.owner.id != @user.id && !@user.master?
      return HESReponder("You may not view this group.", "DENIED")
    else
      return HESResponder(group)
    end
  end

  # Create a group
  #
  # @url [POST] /groups
  # @authorize Public
  def create
    if params[:group].nil? || params[:group][:users].nil? || (!params[:group][:users].is_a?(Hash) && !params[:group][:users].is_a?(Array))
      return HESResponder('Must include group with at least 1 user.', "ERROR")
    end
    users = params[:group].delete(:users)
    group = @user.groups.build(params[:group])
    if !group.valid?
      return HESResponder(group.errors.full_messages, "ERROR")
    end
    Group.transaction do
      group.save!
      users.each do |user|
        u = group.users.build(:user_id => user[:id])
        if !u.valid?
          return HESResponder(u.errors.full_messages, "ERROR")
        end
      end
    end
    return HESResponder(group)
  end

  def update
    group = Group.find(params[:id]) rescue nil
    if !group
      return HESResponder("Group", "NOT_FOUND")
    else
      if group.owner != @user && !@user.master?
        return HESReponder("You may not edit this group.", "DENIED")
      end
      params[:group].delete(:users) if !params[:group][:users].nil?
      Group.transaction do
        group.update_attributes(params[:group])
      end
      if !group.valid?
        return HESResponder(group.errors.full_messages, "ERROR")
      else
        return HESResponder(group)
      end
    end
  end
  
  def destroy
    group = Group.find(params[:id]) rescue nil
    if !group
      return HESResponder("Group", "NOT_FOUND")
    elsif (group.owner == @user || @user.master?) && user.destroy
      return HESResponder(group)
    else
      return HESResponder("Error deleting.", "ERROR")
    end
  end

end
