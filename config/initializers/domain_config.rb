module DomainConfig
  # if you want this site to be served as site.com and/or site.net and/or site.org, put them here
  DomainNames=['healthyworkforce-gokp.org', 'gokp.com', 'go.dev']
  # if you want site.com and/or site.org to be redirected to site.com, put them here
  RedirectDomainNames=['']
  # if you want staging.site.com, dev.site.com, test.site.com to be served as site.com, put staging, dev, test here
  AcceptablePrependages=['staging', 'wombat']

  def self.parse(host) #example: something.staging.site.com.js
    domain=DomainConfig::DomainNames.detect{|dn|host=~/#{dn}/} #example: site.com
    if domain
      prependages=(host[0,host.index(domain)]||'').split('.')
      appendages = (host[host.index(domain)+domain.size+1,host.size] || '').split('.') #example: js
      if (host=~/^#{domain}/).nil? && !AcceptablePrependages.detect{|x|host=~/^#{x}\.#{domain}/} #example: site.com,site.com.js,staging.site.com.js
        subdomain = prependages.delete_at(0)
        acceptable_pp,unacceptable_pp = prependages.partition{|x| AcceptablePrependages.include?(x)} if prependages  # only if host is not.allowed.staging.site.com.js or not.allowed.site.com.js
        recommendation = unacceptable_pp.nil? || unacceptable_pp.empty? ? nil : "#{subdomain}#{".#{acceptable_pp.join('.')}" unless acceptable_pp.empty?}.#{domain}#{".#{appendages.join('.')}" unless appendages.empty?}"
        {:host=>host,:domain=>domain,:subdomain=>subdomain,:prependages=>prependages,:appendages=>appendages,:recommendation=>recommendation}
      else
        {:host=>host,:domain=>domain,:subdomain=>nil,:prependages=>prependages,:appendages=>appendages,:recommendation=>"www.#{domain}#{".#{appendages.join('.')}" unless appendages.empty?}"}
      end   
    else
      {:host=>host,:unknown=>true,:domain=>nil,:subdomain=>nil,:prependages=>nil,:appendages=>nil,:recommendation=>"www.#{DomainNames.first}"}
    end
  end
  
  def self.swap_subdomain(host,subdomain) # examples: thrive.com,my => my.thrive.com    my.staging.thrive.com.js,your => your.staging.thrive.com.js
    info=parse(host)
    pp=(info[:prependages]||[]).join('.')
    d=info[:domain]
    ap=(info[:appendages]||[]).join('.')
    "#{subdomain}#{".#{pp}" unless pp.empty?}.#{d}#{".#{ap}" unless ap.empty?}"
  end
end

