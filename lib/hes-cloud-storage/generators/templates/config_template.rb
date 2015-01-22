HesCloudStorage.configuration = {
  :app_key => "<%=@application["key"]%>",
  :app_folder => "<%=@application["slug"]%>",
  :use_ssl => false,
  :domain => Rails.env.production? ? 'hesapps.com' : 'staging.hesapps.com'
}
