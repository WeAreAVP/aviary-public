# User
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class User < ApplicationRecord
  # Connects this user object to Blacklights gem Bookmarks.
  include Blacklight::User
  # Include default devise modules. Others available are:
  devise :database_authenticatable, :registerable, :rememberable, :trackable, :validatable, :confirmable,
         :recoverable, :invitable

  def active_for_authentication?
    super && status
  end

  def inactive_message
    'Sorry, this account has been deactivated. Please contact administrator.'
  end

  has_many :organizations, dependent: :nullify
  has_many :organization_users, dependent: :destroy
  has_many :saved_searches, dependent: :destroy
  belongs_to :created_by, class_name: 'User', foreign_key: 'created_by', optional: true
  belongs_to :updated_by, class_name: 'User', foreign_key: 'updated_by', optional: true

  validates :email, uniqueness: true, presence: true
  validates :first_name, :last_name, presence: true
  validates_acceptance_of :agreement, message: 'Agreement must be accepted'
  validates :password_confirmation, presence: true, on: :create
  validates :password, confirmation: true, presence: true, on: :create
  # validates_confirmation_of :password
  has_attached_file :photo, styles: { thumb: '200x200>', processors: %i[thumbnail compression] }, default_url: ''
  validates_attachment_content_type :photo, content_type: %r[\Aimage\/.*\z]
  validate :password_complexity
  scope :active_users, -> { where(status: true) }
  before_save :handle_extra_fields

  def handle_extra_fields
    self.username = 'aviary_username' if username.blank?
    self.preferred_language = 'aviary_preferred_language' if preferred_language.blank?
  end

  def password_complexity
    if password.present? && !password.match(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[.@$!%*?&])[A-Za-z\d.@$!%*?&]{8,}$/)
      errors.add :password, 'must have 8 characters and include at least one lowercase letter, one uppercase letter, one number and one special character.'
    end
    true
  end

  def current_org_owner_admin(organization)
    organization_users.where(organization_id: organization.id, status: true).owner_or_admin if organization.present?
  end

  def current_org_owner(organization)
    organization_users.where(organization_id: organization.id, status: true).owner if organization.present?
  end

  def current_org_admin(organization)
    organization_users.where(organization_id: organization.id, status: true).admin if organization.present?
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def full_name_with_email
    "#{first_name} #{last_name} ( #{email} )"
  end

  def self.admin_user_list(page, per_page, sort_column, sort_direction, params)
    q = params[:search][:value]
    if q.present?
      searching_where = ['first_name LIKE (?) OR last_name LIKE (?) OR email LIKE (?)',
                         "%#{q}%", "%#{q}%", "%#{q}%"]
    end
    users = User.select('users.id, users.first_name, users.last_name, users.email')
                .where('users.invitation_token IS NULL')
                .where(searching_where)
                .order(sort_column => sort_direction)
    count = users.size
    users = users.limit(per_page).offset((page - 1) * per_page)

    [users, count]
  end

  def self.admin_user_list_export
    User.select('users.id,users.email,users.first_name,users.last_name, organizations.name as organization, roles.name as role')
        .joins('left  join organization_users on organization_users.user_id = users.id
left  join organizations on organizations.id = organization_users.organization_id
left join roles on roles.id = organization_users.role_id')
  end

  def self.fetch_user_list(_user, page, per_page, sort_column, sort_direction, params, current_org = nil)
    q = params[:search][:value]
    order_mappings = {
      'email_asc' => 'email ASC',
      'email_desc' => 'email DESC',
      'first_name_asc' => 'first_name ASC',
      'first_name_desc' => 'first_name DESC',
      'roles_org.name_asc' => 'roles_org.name ASC',
      'roles_org.name_desc' => 'roles_org.name DESC',
      'om.status_asc' => 'om.status ASC',
      'om.status_desc' => 'om.status DESC'
    }
    if q.present?
      searching_where = ["first_name LIKE (?) OR last_name LIKE (?) OR email LIKE (?)
                          OR roles_org.name LIKE (?)",
                         "%#{q}%", "%#{q}%", "%#{q}%", "%#{q}%"]
    end

    sql_conditions = ['om.organization_id = ?', current_org.try(&:id)] if current_org.present?

    users = User.select('users.id, users.first_name, users.last_name, users.email, om.role_id,
                         om.organization_id, roles_org.name role_name, om.status org_status')
                .joins('LEFT JOIN organization_users om ON om.user_id = users.id')
                .joins('LEFT JOIN roles as roles_org ON om.role_id = roles_org.id ')
                .where('users.invitation_token IS NULL')
                .where('om.token IS NULL')
                .where(sql_conditions).where(searching_where)
                .order(order_mappings["#{sort_column}_#{sort_direction}"])
    count = users.size
    users = users.limit(per_page).offset((page - 1) * per_page)

    [users, count]
  end
end
