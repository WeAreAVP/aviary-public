# Ability
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class Ability
  include CanCan::Ability

  def initialize(user, organization, _ip_address, request = nil)
    user ||= User.new
    can :read, Collection, &:is_public
    can :read, CollectionResourceFile do |resource_file|
      resource_file.access == :yes.to_s
    end
    can :read, CollectionResource do |collection_resource|
      collection_resource.access == :access_public.to_s
    end
    if user.organization_users.active.present? && organization.present?
      user_current_organization = user.organization_users.active.where(organization_id: organization.id)
      if user_current_organization.present?
        can :manage, Interviews::Interview
        unless user_current_organization.first.role.system_name == 'ohms_assigned_user'
          can :manage, CollectionResource
          can :manage, Playlist
          can :manage, Organization
          can :manage, Collection
          can :manage, [FileIndex, FileIndexPoint]
          can :manage, [FileTranscript, FileTranscriptPoint]
          can :manage, [AnnotationSet, Annotation]
          can :manage, CollectionResourceFile
          roles = Role.org_owner_and_admin_id
          unless roles.include? user_current_organization.first.role_id
            cannot :destroy, Collection
            cannot :destroy, CollectionResource
          end
        end
      end
    end
    if request.GET['share'].present? || request.GET['access'].present?
      begin
        if Utilities::PublicShareUtilities.should_have_public_access(request.GET['share'], request.path) || Utilities::PublicShareUtilities.public_access_handler(request.GET['access'], request.path)
          can :read, CollectionResource do |collection_resource|
            collection_resource.can_view = true
            true
          end
          can :read, CollectionResourceFile do |_resource_file|
            true
          end
          if request.url.include?('playlist')
            can :read, Playlist do |_playlist|
              true
            end
          end
        end
      rescue StandardError => ex
        puts ex
      end
    end
    can :edit, Organization do |organization_obj|
      user_current_organization = user.organization_users.active
      user_current_organization.pluck(:organization_id).include?(organization_obj.id)
    end
  end
end
