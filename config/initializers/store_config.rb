# originally named StoreConfig, original syntax was StoreConfig.for_promotion(@promotion)
# now named StoreConfig, new syntax is StoreConfig.get_items_for_promotion(@promotion)


# not sure how we should handle this... it's a TON of work normalizing this, and i don't want to get it wrong and rework it.  let's hard-code it and go from there :)


# it would be nice if this was a normalized database structure, but we need to decide what it should be before we try modeling it 
#   - it got more and more complicated every time we talked about it 
#      - meeting 1:  buy a fit bit
#      - meeting 2:  let them get a fitbit + shirt
#      - meeting 3:  if they already have a fitbit, ask them if they want to buy just the shirt
#      - meeting 4:  we need to add $1.40 if they choose XXL
#      - meeting 76: still more changes

module StoreConfig 
  def self.get_items_for_promotion(promotion,user=nil)
    items = get_all_items_for_promotion(promotion)
    items.select do |pkg|
      if pkg[:sales_limit]
        # EXAMPLE
        # :sales_limit => {:max=>100,:keys=>['SHIRT_PLUS_ZIP','ZIP_ONLY']}
        #   count all orders having those keys, and kick-out item when count > max
        order_count = Order.count(:all,:include=>:user,:conditions=>["users.promotion_id = ? and item_key in (?)",promotion.id,pkg[:sales_limit][:keys]]).to_i
        order_count < pkg[:sales_limit][:max]
      else
        true
      end
    end
  end

  #NOTE: do not call this method.  get_all_items_for_promotion will *not* hide items that have reached their sales cap
  def self.get_all_items_for_promotion(promotion)
    # look for a item with a key that matches the subdomain, or return the default
    # if a hash is found, return it
    # if a symbol is found, then return the item with a matching key; or return the default if misconfigured

    found = STORE_PACKAGES[promotion.reload.subdomain.downcase.strip]
    if found
      if found.is_a?(Symbol)
        STORE_PACKAGES[found] || STORE_PACKAGES[:default]
      else
        found
      end
    else
      STORE_PACKAGES[:default]
    end 
  end

  STORE_PACKAGES = {
    :default => [],
    
    :flex_only => [
      {
         :key => "FLEX_ONLY",
         :title => "Fitbit Flex",
         :image => "/images/fitbit/item_flexonly.png",
         :gray_image => "/images/fitbit/gray-item_flexonly.png",
         :price => 50.00,
         :shippable => true, 
         :email_confirmation => "Your Flex&trade; will ship in 3-5 business days. Review the <a href=\"http://files.hesapps.com/passport/Passport-Fitbit-Getting-Started.pdf\">Getting Started Guide</a> to learn how to connect your Fitbit with your <i>Health for the Holidays</i> account."
      }
    ],

    :one_only => [
      {
         :key => "ONE_ONLY",
         :title => "Fitbit One",
         :image => "/images/fitbit/item_oneonly.png",
         :gray_image => "/images/fitbit/gray-item_oneonly.png",
         :price => 40.00,
         :shippable => true, 
         :email_confirmation => "Your One&trade; will ship in 3-5 business days. Review the <a href=\"http://files.hesapps.com/passport/Passport-Fitbit-Getting-Started.pdf\">Getting Started Guide</a> to learn how to connect your Fitbit with your <i>Health for the Holidays</i> account."
      }
    ],

    :zip_only => [
      {
         :key => "ZIP_ONLY",
         :title => "Fitbit Zip",
         :image => "/images/fitbit/item_ziponly.png",
         :gray_image => "/images/fitbit/gray-item_ziponly.png",
         :price => 30.00,
         :shippable => true, 
         :email_confirmation => "Your Zip&trade; will ship in 3-5 business days. Review the <a href=\"http://files.hesapps.com/passport/Passport-Fitbit-Getting-Started.pdf\">Getting Started Guide</a> to learn how to connect your Fitbit with your <i>Health for the Holidays</i> account."
      }
    ],

    :flex_and_one => [
      {
         :key => "FLEX_ONLY",
         :title => "Fitbit Flex",
         :image => "/images/fitbit/item_flexonly.png",
         :gray_image => "/images/fitbit/gray-item_flexonly.png",
         :price => 50.00,
         :shippable => true, 
         :email_confirmation => "Your Flex&trade; will ship in 3-5 business days. Review the <a href=\"http://files.hesapps.com/passport/Passport-Fitbit-Getting-Started.pdf\">Getting Started Guide</a> to learn how to connect your Fitbit with your <i>Health for the Holidays</i> account."
      },
      {
         :key => "ONE_ONLY",
         :title => "Fitbit One",
         :image => "/images/fitbit/item_oneonly.png",
         :gray_image => "/images/fitbit/gray-item_oneonly.png",
         :price => 40.00,
         :shippable => true, 
         :email_confirmation => "Your One&trade; will ship in 3-5 business days. Review the <a href=\"http://files.hesapps.com/passport/Passport-Fitbit-Getting-Started.pdf\">Getting Started Guide</a> to learn how to connect your Fitbit with your <i>Health for the Holidays</i> account."
      }
    ],

    :zip_and_flex => [
      {
         :key => "ZIP_ONLY",
         :title => "Fitbit Zip",
         :image => "/images/fitbit/item_ziponly.png",
         :gray_image => "/images/fitbit/gray-item_ziponly.png",
         :price => 30.00,
         :shippable => true, 
         :email_confirmation => "Your Zip&trade; will ship in 3-5 business days. Review the <a href=\"http://files.hesapps.com/passport/Passport-Fitbit-Getting-Started.pdf\">Getting Started Guide</a> to learn how to connect your Fitbit with your <i>Health for the Holidays</i> account."
      },
      {
         :key => "FLEX_ONLY",
         :title => "Fitbit Flex",
         :image => "/images/fitbit/item_flexonly.png",
         :gray_image => "/images/fitbit/gray-item_flexonly.png",
         :price => 50.00,
         :shippable => true, 
         :email_confirmation => "Your Flex&trade; will ship in 3-5 business days. Review the <a href=\"http://files.hesapps.com/passport/Passport-Fitbit-Getting-Started.pdf\">Getting Started Guide</a> to learn how to connect your Fitbit with your <i>Health for the Holidays</i> account."
      }
    ]
  }
end

# TO USE THE PRE-DEFINED PACKAGE AS-IS WITHOUT CHANGES, SPECIFY A SUBDOMAIN AS A STRING AND A PACKAGE KEY AS A SYMBOL
StoreConfig::STORE_PACKAGES['fitbit'] = []
StoreConfig::STORE_PACKAGES['fitbit'] << StoreConfig::STORE_PACKAGES[:zip_only].first.dup
StoreConfig::STORE_PACKAGES['fitbit'][0][:sales_limit] = {:max => 2, :keys => ['ZIP_ONLY']}

StoreConfig::STORE_PACKAGES['fitbit1'] = :zip_and_flex

StoreConfig::STORE_PACKAGES['fitbit2'] = []
StoreConfig::STORE_PACKAGES['fitbit2'] << StoreConfig::STORE_PACKAGES[:zip_only].first.dup
StoreConfig::STORE_PACKAGES['fitbit2'][0][:sales_limit] = {:max => 2, :keys => ['ZIP_ONLY']}

# TEMPLATES
#   - copy the default, and multiply

StoreConfig::STORE_PACKAGES[:fifty_cent] = StoreConfig::STORE_PACKAGES[:flex_only].collect{|h|h.dup}
StoreConfig::STORE_PACKAGES[:fifty_cent][0][:price] = 0.5
StoreConfig::STORE_PACKAGES['qa'] = :fifty_cent


StoreConfig::STORE_PACKAGES['byofitbitorbuy'] = :zip_only
StoreConfig::STORE_PACKAGES['buyfitbitormanual'] = :zip_only

StoreConfig::STORE_PACKAGES['fitbitsaleslimit'] = []
StoreConfig::STORE_PACKAGES['fitbitsaleslimit'] << StoreConfig::STORE_PACKAGES[:zip_only].first.dup
StoreConfig::STORE_PACKAGES['fitbitsaleslimit'][0][:sales_limit] = {:max => 1, :keys => ['ZIP_ONLY']}
StoreConfig::STORE_PACKAGES['fitbitsaleslimit'][0][:price] = 0.5
