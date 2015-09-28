class StoreController < ApplicationController
  authorize :index, :place_order, :user

  # Get the available items for a promotion
  #
  # @url [GET] /store
  # @authorize User
  # @return [Array<Obj>] JSON objects representing store items 
  #
  # [URL] /store [GET]
  #  [200 OK] Success
  #   # Example response
  #    {
  #      "payment_types": ["C"],
  #      "items": [
  #        {
  #          "title": "Zip only",
  #          "gray_image": "/images/fitbit/gray-item_ziponly.jpg",
  #          "image": "/images/fitbit/item_ziponly.jpg",
  #          "key": "ZIP_ONLY",
  #          "price": 35.0,
  #          "shippable": true,
  #          "email_confirmation": "Your Zip&trade; will ship in 3-5 business days. . . ."
  #        },
  #        {
  #          "title": "I already have a Fitbit",
  #          "gray_image": "/images/fitbit/gray-item_haveone.jpg",
  #          "image": "/images/fitbit/item_haveone.jpg",
  #          "key": "ALREADY_HAS_FITBIT",
  #          "price": 0,
  #          "shippable": false
  #        },
  #        {
  #          "title": "Log progress manually",
  #          "gray_image": "/images/fitbit/gray-item_manual.jpg",
  #          "image": "/images/fitbit/item_manual.jpg",
  #          "key": "MANUAL",
  #          "price": 0,
  #          "shippable": false
  #        }
  #      ]
  #    }
  def index
    # only allow 1 order
    if @target_user.orders.count == 0
      hash = {:payment_types=>['C']}
      hash[:items] = StoreConfig.get_items_for_promotion(@promotion,@target_user)
      respond_with hash
    else
      empty_hash = {:payment_types=>[],:items=>[]}
      respond_with empty_hash
    end
  end

  # Create an order for a user
  #
  # @url [POST] /store/place_order
  # @authorize User
  # @param [String] key The key of the item to be ordered
  # @param [String] payment_type The type of payment to be made
  # @param [String] credit_card_number The credit card to be charged (if payment type is C)
  # @param [String] credit_card_expiration The expiration date of the credit card to be charged (if payment type is C)
  # @param [String] line_1 The 1st line of the shipping address. *ignored if item is not shippable*
  # @param [String] line_2 The 2nd line of the shipping address. *ignored if item is not shippable*
  # @param [String] city The city of the shipping address. *ignored if item is not shippable*
  # @param [String] state The state of the shipping address. *ignored if item is not shippable*
  # @param [String] postal_code The postal code of the shipping address. *ignored if item is not shippable*
  # @param [String] force If the item is not shippable and has a price of 0, a 422 will be returned.  Set this to true to force the creation of an order *only in that edge case*
  # @return [JSON] Order if success, {:errors=>"message"} if failure 
  def place_order
    key = params[:key]
    if key
      items = StoreConfig.get_items_for_promotion(@promotion,@target_user)
      item = items.detect{|p|p[:key]==key}
      if item
        # TODO: can user only order 1 of them?  (i.e. can i just keep ordering discounted fitbits at $35.00?).  probably need to limit this.
        order = @target_user.orders.build

        if item[:shippable]
          unless params[:line_1].to_s.strip.empty? || params[:city].to_s.strip.empty? || params[:state].to_s.strip.empty? || params[:postal_code].to_s.strip.empty?
            order.line_1 = params[:line_1]
            order.line_2 = params[:line_2]
            order.city = params[:city]
            order.state = params[:state]
            order.postal_code = params[:postal_code]
          else
            render :json => {:errors => "key #{key} is shippable but line_1, city, state, and/or postal_code is missing."}, :status =>  422 and return
          end
        end

        if item[:price] > 0
          result = process_payment(order,item)
          if result[:success]
            order.save
            # FitbitEmailer.fitbit_receipt(@target_user).deliver
            render :json => order and return
          else
            render :json => {:errors => result[:message]}, :status =>  422 and return
          end
        elsif item[:shippable] || (!item[:shippable] && params[:force].to_s.strip.downcase == 'true')
          #create order; no payment necessary.
          order.item_key = item[:key]
          order.save
          # FitbitEmailer.fitbit_receipt(@target_user).deliver
          render :json => order and return
        else
          render :json => {:errors => "key #{key} has a price of 0 and is not shippable.  An order will not be created."}, :status =>  422 and return
        end
      else
        render :json => {:errors => "unknown key: #{key}"}, :status =>  422 and return
      end
    else
      render :json => {:errors => "key not specified"}, :status =>  422 and return
    end
  end

  :private
  def process_payment(order,item)

    #!!! DEBUG ONLY
    # next 2 lines skip payment processing.  don't deploy to production!
    # order.attributes={:total_amount=>item[:price],:item_key=>item[:key],:payment_type=>'C',:last_4=>'1234'}
    # return {:success=>true}
    #!!! END DEBUG ONLY


    # ensure user is attempting to make payment via an allowed method
    allowed = []
    allowed << 'C'  # always allow credit card (right?)
    if false 
      # F means free -- i.e. no payment required, even though the price is > 0
      # the user experience is:  this costs $35, enter your address to have it shipped to you [and no payment is taken from the user]
      # it is very rare to use this. it only happens when a client wants to take payments in an esoteric manner (please send cash, etc)
      # hence "if false"
      allowed = ['F']
    end

    payment_type = params[:payment_type].to_s.strip

    if payment_type.empty? 
      return {:success=>false,:message=>"Payment type not specified"}
    elsif !allowed.include?(payment_type)
      return {:success=>false,:message=>"Payment type '#{payment_type}' not allowed."}
    end

    item_key = item[:key]
    order.item_key=item_key
    total_price = item[:price]

    if item[:additional_options]
      # e.g. shirt
      item[:additional_options].each_with_index do |o,i|
        chosen = params[:additional_options]["additional_#{i+1}".to_sym]
        order.attributes["additional_#{i+1}"] = chosen
        # e.g. shirt size
        o[:options].each_with_index do |option,option_index|
          if option[:key]==chosen
            if option[:price_adjustment]
              total_price += option[:price_adjustment]
            end
          end
        end
      end
    end

    order.total_amount = total_price

    if payment_type=='C'
      unless params[:credit_card_number] && params[:credit_card_expiration]
        return {:success=>false,:message=>"Card number or expiration date missing"}
      end

      #DEBUG ONLY
      #if Rails.env == 'development'
      #  return {:success=>true}
      #end

      if defined?(HESSecure::AuthorizeNetLogin)
        gateway = ActiveMerchant::Billing::AuthorizeNetGateway.new(:login => HESSecure::AuthorizeNetLogin, :password => HESSecure::AuthorizeNetKey)

        amount_in_cents = order.total_amount * 100
 
        #example params {"fitbit_payment"=>{"credit_card_expiration"=>"082016", "payment_type"=>"C", "credit_card_number"=>"4111111111111111"}}
        xp = params[:credit_card_expiration]
        cc = ActiveMerchant::Billing::CreditCard.new(
          :number => params[:credit_card_number],
          :month => xp[0,2],
          :year => "20#{xp[xp.size-2,2].to_i}",
          :first_name => order.user.first_name,
          :last_name => order.user.last_name,
          :require_verification_value => false
        )
        
        return {:success=>false,:message=>"Card number or expiration date invalid"} unless cc.valid?

        response = gateway.authorize(amount_in_cents, cc, {
          :customer => order.user.full_name,
          :email => order.user.email,
          # order_id is optional but if present must be unique, and it's frickin difficult to do that
          #:order_id => "#{Date.today}-#{@promotion.subdomain}-#{(Time.now.utc - Time.now.utc.midnight) * 1000000}",
          # description is a max of 255 chars
          :description => "#{@promotion.program_name} - #{@promotion.subdomain} - #{item_key} - #{order.user.email}"[0..254]})
        
        if response.success?
          gateway.capture(amount_in_cents,response.authorization)
          last4 = params[:credit_card_number].to_s[12,4]
          order.payment_type='C'
          return {:success=>true}
        else
          return {:success=>false,:message=>"Payment error:\n#{response.message}"}
        end
      else
        return {:success=>false,:message=>"Payment gateway credentials not found."}
      end
    else
      # if we take other payment types some day, they go here...
      order.payment_type=payment_type
      return {:success=>true}
    end
  end
end
