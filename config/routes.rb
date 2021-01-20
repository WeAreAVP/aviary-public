Rails.application.routes.draw do
  concern :range_searchable, BlacklightRangeLimit::Routes::RangeSearchable.new
  mount Blacklight::Engine => '/'
  mount BlacklightAdvancedSearch::Engine => '/'

  concern :searchable, Blacklight::Routes::Searchable.new
  resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
    concerns :searchable
    concerns :range_searchable
    collection do
      post :update_selected_playlist
      post :assign_to_playlist
    end
  end
  devise_for :admins
  root 'home#index'
  get '/collection', to: 'home#index', as: :org_collection
  get '/playlist', to: 'home#index', as: :org_playlist
  get '/aboutus', to: 'home#index', as: :org_aboutus
  get '/robots.:format' => 'home#robots', constraints: { format: /(txt)/ }
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    passwords: 'users/passwords',
    invitations: 'users/invitations',
    confirmations: 'users/confirmations'
  }
  devise_scope :user do
    get '/profile', to: 'devise/registrations#edit'
  end
  post '/update_resource_column_sort/:id', to: 'organizations#update_resource_column_sort', as: 'update_resource_column_sort'
  post '/update_resource_file_column/:id', to: 'organizations#update_resource_file_column', as: 'update_resource_file_column'
  get 'forbidden', to: 'home#forbidden', as: :forbidden
  get 'notfound', to: 'home#not_found', as: :not_found
  get 'get_collections', to: 'home#featured_collections', as: :get_collections
  get 'get_playlists', to: 'home#featured_playlists', as: :get_playlists
  get 'get_resources', to: 'home#featured_resources', as: :get_resources
  get 'get_organization', to: 'home#featured_organization', as: :get_organization
  get 'record_tracking', to: 'home#record_tracking', as: :record_tracking
  get 'get_collectionwise_resources/:id', to: 'home#collection_wise_resources', as: :get_collectionwise_resources
  get 'users/add_member_row', to: 'users#add_member_row', as: :add_member_row
  namespace :admin do
    resources :users, except: %i[show] do
      put '/organization', to: 'users#organization_update'
      delete '/organization/:org_user_id', to: 'users#organization_destory', as: :organization_delete
      post '/organization', to: 'users#organization_create'

      collection do
        get '/pending', to: 'users#pending'
        get '/export_users', to: 'users#export'
      end
    end

    get '/', to: 'users#index'
  end

  resources :users, only: %i[destroy index] do
    post '/add_new_member', to: 'users#add_new_member', as: :add_new_member
    post '/change_org_status', to: 'users#change_org_status', as: :change_org_status
    post '/change_org_role', to: 'users#change_org_role', as: :change_org_role
    get '/remove_user(/:organization_id)', to: 'users#remove_user', as: :remove_user
  end

  get 'pricing', to: 'home#pricing', as: :pricing
  get 'terms_of_service', to: 'home#terms_of_service', as: :terms_of_service
  get 'privacy_policy', to: 'home#privacy_policy', as: :privacy_policy
  get 'contact_us', to: 'home#contact_us', as: :contact_us
  get 'support', to: 'home#support', as: :support
  get 'about', to: 'home#about', as: :about
  get 'features', to: 'home#features', as: :features
  post 'submit_request', to: 'home#submit_request', as: :submit_request
  resources :organizations, only: %i[index show update]
  get '/organization_profile', to: 'organizations#edit', as: :edit_organization
  get '/display_settings', to: 'organizations#display_settings', as: :display_settings_organization
  match '/search_configuration', to: 'organizations#search_configuration', as: :search_configuration_organization, via: %i[get post]
  post '/set_layout', to: 'home#set_layout'

  resources :collection_resource_files do
    collection do
      post :data_table, to: 'collection_resource_files#index'
      post :bulk_resource_file_edit
      get :export_resource_file
      get :bulk_resource_list
    end
  end
  resources :collections do
    member do
      get 'edit/(:tab_type)', to: 'collections#edit', as: :edit_with_tab
      post :edit
      post :general_settings
      post :create_custom_fields
      get :new_edit_custom_field
      post :update_sort_fields
      get :delete_custom_meta_fields
      get :list_resources
      post :list_resources
      get 'collection_resources/new', to: 'collection_resources#new'
      post :import, to: 'collections#import'
    end
    collection do
      get '(/:collection_id)/export', to: 'collections#export', as: :export
      get :bulk_resource_list
      post :bulk_edit_operation
      get :fetch_bulk_edit_resource_list
      get :update_progress
      get :update_progress_files
    end
    resources :collection_resources do
      get :add_resource_file
      post :save_resource_file
      put :update_file_name
      get '/load_resource_details_template(/file/:resource_file_id)', to: 'collection_resources#load_resource_details_template', as: 'load_resource_details_template'
      get '/load_index(/file/:resource_file_id)', to: 'collection_resources#load_index_template', as: 'load_index_template'
      get '/load_transcript(/file/:resource_file_id)', to: 'collection_resources#load_transcript_template', as: 'load_transcript_template'
      get '/show_search_counts/file(/:resource_file_id)', to: 'collection_resources#show_search_counts', as: 'show_search_counts'
      post '/file_wise_counts/:collection_resource_id', to: 'collection_resources#file_wise_counts', as: 'file_wise_counts'
      get '/load_head_and_tombstone_template', to: 'collection_resources#load_head_and_tombstone_template', as: 'load_head_and_tombstone_template'
      post '/update_thumbnail/:collection_resource_file_id', to: 'collection_resources#update_thumbnail', as: 'update_thumbnail'
      post :resource_file_sort
      get '/edit', to: 'collection_resources#edit'
      get '(/file/:resource_file_id)(/:view_type)(/:tab_type)', to: 'collection_resources#show', as: 'details', format: false, constraints: { id: /.+/, name: /.+/, encrypted_id: /.+/ }
      delete 'delete_resource_file/:resource_file_id', to: 'collection_resources#delete_resource_file', as: :delete_resource_file
      put 'update_details', to: 'collection_resources#update_details', as: 'update_details'
      patch 'update_metadata', to: 'collection_resources#update_metadata', as: 'update_metadata'
    end
  end
  resources :playlists, except: %i[edit show] do
    resources :playlist_resources do
      collection do
        post :sort
        get :bulk_delete
        get :list_playlist_items
      end
      member do
        post :toggle_item
        post :update_description
        put :update_description
      end
      resources :playlist_items do
        member do
          post :set_start_end_time
        end
      end
      post '/collection_resource_file/:collection_resource_file_id/search_text', to: 'playlist_resources#search_text', as: :search_text
    end
    member do
      get 'edit', to: 'playlists#edit', as: :edit_with_tab
      post 'update_selected_tab', to: 'playlists#update_selected_tab', as: :update_selected_tab
    end
    get '/show(/playlist_resource_id/:playlist_resource_id)(/playlist_item_id/:playlist_item_id)(/collection_resource_file_id/:collection_resource_file_id)(/:pst/:pet)', to: 'playlists#show', as: :show, constraints: { pst: /.*/, pet: /.*/ }
    get '/edit/(playlist_resource/:playlist_resource_id/(playlist_item/:playlist_item_id))(/collection_resource_file/:collection_resource_file_id)', to: 'playlists#edit', as: :edit
    get 'add_resource_to_playlist/:collection_resource_id', to: 'playlists#add_resource_to_playlist', as: :add_to_resource
    collection do
      get 'fetch_resource_list', to: 'playlists#fetch_resource_list', as: :fetch_resource_list
    end
  end
  get 'playlist/add_to_playlist_listing', to: 'playlists#listing_for_add_to_playlist', as: :listing_for_add_to_playlist
  get 'playlist/playlist_export', to: 'playlists#export', as: :playlist_export

  resources :permission_groups, except: [:show] do
    get :autocomplete, on: :collection
  end

  get '/embed/media/:resource_file_id', to: 'collection_resources#embed_file', as: 'embed_file'
  resources :collection_resources, except: %i[edit update] do
    collection do
      post :data_table, to: 'collection_resources#index'
    end
  end

  post 'indexes/upload/:resource_file_id(/:file_index_id)', to: 'indexes#create', as: 'upload_index'
  patch 'indexes/sort/:resource_file_id', to: 'indexes#sort', as: 'index_sort'
  delete 'indexes/delete/:id', to: 'indexes#destroy', as: 'delete_file_index'
  post 'transcripts/upload/:resource_file_id(/:file_transcript_id)', to: 'transcripts#create', as: 'transcript_upload'
  patch 'transcripts/sort/:resource_file_id', to: 'transcripts#sort', as: 'transcript_sort'
  delete 'transcripts/delete/:id', to: 'transcripts#destroy', as: 'transcript_delete'
  get 'transcripts/export/:type(/:id)', to: 'transcripts#export', as: 'transcript_export'
  post :data_table, to: 'collection_resources#index'
  get '/confirm_organization_invite/:token', to: 'organizations#confirm_invite', as: :org_confirm_invite
  get 'remove_image/:target_type/target_id/:target_id/target_attr/:target_attr', to: 'home#remove_image_for_assets', as: :remove_image_target_wise
  get 'r/:noid', to: 'home#noid', as: :noid
  get 'p/:encoded_id', to: 'home#playlist_share', as: :playlist_short
  get 'encrypted_info/(:text_to_be_encrypted)', to: 'home#encrypted_info', as: :encrypted_info
  get 'c/embed/:custom_unique_identifier/(:sequential_number_of_media_file)/(:seconds_to_start_time)', to: 'home#resource_unique_identifier', as: :resource_unique_identifier_embed, format: false, constraints: { custom_unique_identifier: /.+/ }
  get 'c/:custom_unique_identifier/(:sequential_number_of_media_file)/(:seconds_to_start_time)', to: 'home#resource_unique_identifier', as: :resource_unique_identifier, format: false, constraints: { custom_unique_identifier: /.+/ }
  get 'media_rss/:id', to: 'home#media', as: :media_rss
  get 'download_media/:id', to: 'home#download_media', as: :download_media

  get '/reports/org_monthly_resource_csv_report', to: 'reports#org_monthly_resource_csv_report', as: :monthly_resource_csv_report

  get '/api/resource_files_tobe_sync', to: 'api#resource_files_tobe_sync', as: :resource_files_tobe_sync
  post '/api/update_archive_id', to: 'api#update_archive_id', as: :update_archive_id
end
