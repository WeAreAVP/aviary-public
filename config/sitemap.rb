# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = root_url(host: ENV['APP_HOST'])
SitemapGenerator::Sitemap.compress = false
SitemapGenerator::Sitemap.create do
  add pricing_path
  add terms_of_service_path
  add privacy_policy_path
  add contact_us_path
  add support_path
  add about_path
  add features_path
  add organizations_path
  add new_user_session_path
  add new_user_registration_path
end
Organization.where(status: true).each do |organization|
  domain = organization.custom_domain.present? ? organization.custom_domain : "#{organization.url}.#{ENV['APP_HOST']}"
  SitemapGenerator::Sitemap.default_host = root_url(host: domain)
  SitemapGenerator::Sitemap.compress = false
  SitemapGenerator::Sitemap.sitemaps_path = "sitemaps/#{organization.id}"
  SitemapGenerator::Sitemap.create do
    collections = organization.collections.public_collections
    collections.each do |collection|
      add collection_path(collection)
      collection.collection_resources.public_visible.each do |resource|
        add collection_collection_resource_details_path(collection, resource)
      end
    end
    playlists = organization.playlists.public_playlists
    playlists.each do |playlist|
      add playlist_show_path(playlist)
    end
  end
end
