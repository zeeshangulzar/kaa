class PromotionsController < ApplicationController
  authorize :index, :create, :update, :destroy, :master

  authorize :show, :current, :top_location_stats, :verify_users_for_achievements, :authenticate, :can_register, :public
  authorize :index, :poster
  authorize :get_grouped_promotions, :coordinator
  authorize :create, :update, :destroy, :keywords, :one_time_email, :master

  def index
    promotions = params[:organization_id] ? Organization.find(params[:organization_id]).promotions : params[:reseller_id] ? Reseller.find(params[:reseller_id]).promotions : nil
    if promotions.nil?
      active_sql = (params[:active] && params[:active].to_i == 1) ? Promotion.active_scope_sql : '1 = 1'
      sql = "SELECT id, subdomain, registration_starts_on, registration_ends_on, program_length, name, launch_on FROM promotions WHERE 1 = 1 AND #{active_sql}"
      rows = Promotion.connection.select_all(sql)
      promotions = []
      rows.each_with_index{ |row,index|
        promotion = {
          :id                           => row["id"],
          :subdomain                    => row["subdomain"],
          :registration_starts_on       => row["registration_starts_on"],
          :registration_ends_on         => row["registration_ends_on"],
          :program_length               => row["program_length"],
          :name                         => row["name"],
          :launch_on                    => row["launch_on"]
        }
        promotions[index] = promotion
      }
    end
    return HESResponder(promotions)
  end

  def get_grouped_promotions
    conditions = (params[:active_only]=='true' || @current_user.poster?) ? "(promotions.disabled_on is null or promotions.disabled_on > now()) and " : ""
    if @current_user.master?
    elsif @current_user.reseller?
      conditions << "organizations.reseller_id = #{User.sanitize @current_user.promotion.organization.reseller_id}"
    elsif @current_user.coordinator? || @current_user.location_coordinator
      conditions << "promotions.organization_id = #{User.sanitize @current_user.promotion.organization_id}"
    elsif (@current_user.super_coordinator? rescue false)
      conditions << "promotions.id in (#{@current_user.super_coordinator_promotions.all.collect{|scp|User.sanitize(scp.promotion_id)}.join(',')})"
    end

    sql = "SELECT promotions.id promotion_id, promotions.subdomain, promotions.launch_on, promotions.starts_on, organizations.id organization_id, organizations.name organization_name
    FROM promotions
    inner join organizations on organizations.id = promotions.organization_id
    #{"WHERE #{conditions}" unless conditions.empty?}
    order by organizations.name, promotions.subdomain"

    rows = Promotion.connection.select_all sql
    render :json => rows.to_json
  end

  def show
    promotion = (params[:id] == 'current') ? @promotion : Promotion.find(params[:id]) rescue nil
    if !promotion
      return HESResponder(Promotion, "NOT_FOUND")
    end
    return HESResponder(promotion)
  end

  def current
    if @current_user && !@current_user.master?
      seconds_to_midnight = (@promotion.current_date + 1).to_time.to_i - @promotion.current_time.to_i # expire promotion cache at start of new day so frontend can use @promotion.current_date
      return HESCachedResponder(@promotion.cache_key, @promotion, {:cache_options=>{:expires_in => seconds_to_midnight}})
    end
    return HESResponder(@promotion)
  end

  def create
    promotion = nil
    Promotion.transaction do
      promotion = Promotion.create(params[:promotion])
      if !promotion || !promotion.valid?
        return HESResponder(promotion.errors.full_messages, "ERROR")
      else
        if !params[:promotion][:flags].nil?
          params[:promotion][:flags].each{|f,v|
            if !promotion.flags[f.to_sym].nil?
              promotion.flags[f.to_sym] = v
            end
          }
          promotion.save!
        end
      end
    end
    return HESResponder(promotion)
  end
  
  def update
    promotion = Promotion.find(params[:id])
    if !promotion
      return HESResponder("Promotion", "NOT_FOUND")
    else
      Promotion.transaction do
        promotion.update_attributes(params[:promotion])
        if !params[:promotion][:flags].nil?
          params[:promotion][:flags].each{|f,v|
            if !promotion.flags[f.to_sym].nil?
              promotion.flags[f.to_sym] = v
            end
          }
          promotion.save!
        end
      end
      if !promotion.valid?
        return HESResponder(promotion.errors.full_messages, "ERROR")
      else
        return HESResponder(promotion)
      end
    end
  end
  
  def destroy
    promotion = Promotion.find(params[:id]) rescue nil
    if !promotion
      return HESResponder("Promotion", "NOT_FOUND")
    elsif promotion.destroy
      return HESResponder(promotion)
    else
      return HESResponder("Error deleting.", "ERROR")
    end
  end

  def top_location_stats
    users = ActiveRecord::Base.connection.select_all("SELECT COUNT(*) AS 'user_count', locations.name FROM users INNER JOIN locations ON users.top_level_location_id = locations.id WHERE users.promotion_id = #{@promotion.id} GROUP BY locations.name;")
    render :json => {:data => users} and return
  end

  def keywords
    return HESResponder(@promotion.keywords)
  end

  def authenticate
    if params[:password] == @promotion.pilot_password
      return HESResponder()
    else
      return HESResponder("Invalid pilot password.", "UNAUTHORIZED")
    end
  end

  def can_register
    return HESResponder() if @promotion.max_participants.nil? || @promotion.max_participants > @promotion.total_participants
    return HESResponder("Maximum participants reached.", "ERROR")
  end

  def one_time_email
    promotion = Promotion.find(params[:promotion_id]) rescue nil
    head :not_found and return unless promotion

    recipients = 
    if params[:email][:recipients].is_a?(Array)
      params[:email][:recipients]
    else
      arr = params[:email][:recipients].split("\n")
      other_splitters = [",",";","|"]
      other_splitters.each do |splitter|
        arr = arr.collect{|r|r.split(splitter)}.flatten
      end
      arr.delete("\r")
      arr.delete("")
      arr
    end

    if params[:email][:include_all] == true
      recipients = (recipients.concat promotion.all_user_emails).uniq
    end

    if params[:email][:include_team_leaders] == true
      recipients = (recipients.concat promotion.all_team_leaders_current_competition_emails).uniq
    end

    if params[:email][:include_unofficial_team_leaders] == true
      recipients = (recipients.concat promotion.all_unofficial_current_competition_team_leaders_emails).uniq
    end

    markdown_body = Markdown.new(params[:email][:body]).to_html #.gsub(/^<p>/,'').gsub(/<\/p>$/,'')

    #host=DomainConfig.swap_subdomain(request.host,@promotion.subdomain)
    host="#{promotion.subdomain}.#{DomainConfig::DomainNames.first}"
    way=""
    if recipients.size >= 10
      # QUEUE
      tmail = GoMailer.one_time_email(recipients,params[:email][:subject],markdown_body, nil, promotion)
      tag = "#{APPLICATION_NAME.downcase}-one-time-email-#{@promotion.subdomain}-#{Time.now.strftime('%Y%m%d-%H%M%S')}"
      Rails.logger.info "recipients are #{recipients.inspect}"
      tmails = recipients.collect{|x|tmail}
      XmlEmailDelivery.deliver_many(tmails,tag,recipients)
      way=" were queued for delivery tomorrow."
    else 
      # SEND NOW 
      recipients.each do |recipient|
        GoMailer.one_time_email(recipient,params[:email][:subject],markdown_body, nil, promotion).deliver
      end
      way=" have been delivered."
    end
    render :json=>{:message=>"#{recipients.size} messages #{way}"}
  end

end
