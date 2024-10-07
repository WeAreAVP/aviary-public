# Creates default super_admin user and default roles '
puts '============================ Roles ============================'
puts '==============================================================='

roles = %w(organization_owner organization_admin organization_user)
roles.each do |r|
  Role.where(system_name: r, name: r.gsub("_", " ").titleize).first_or_create
end
puts '============================  Admin ============================'
puts '================================================================'
user = Admin.where(email: 'admin@demo.com').first_or_initialize
user.first_name = 'AVIARY'
user.last_name = 'ADMIN'
user.password = 'demoadmin'
user.password_confirmation = 'demoadmin'
user.username = 'admin'
user.agreement = 1
user.save(validate: false)

puts '======================== Default Fields ========================'
puts '================================================================'
agents = ['Abridger',
          'Actor',
          'Adapter',
          'Addressee',
          'Analyst',
          'Animator',
          'Annotator',
          'Appellant',
          'Appellee',
          'Applicant',
          'Architect',
          'Arranger',
          'Art copyist',
          'Art director',
          'Artist',
          'Artistic director',
          'Assignee',
          'Associated name',
          'Attributed name',
          'Auctioneer',
          'Author',
          'Author in quotations or text abstracts',
          'Author of afterword, colophon, etc.',
          'Author of dialog',
          'Author of introduction, etc.',
          'Autographer',
          'Bibliographic antecedent',
          'Binder',
          'Binding designer',
          'Blurb writer',
          'Book designer',
          'Book producer',
          'Bookjacket designer',
          'Bookplate designer',
          'Bookseller',
          'Braille embosser',
          'Broadcaster',
          'Calligrapher',
          'Cartographer',
          'Caster',
          'Censor',
          'Choreographer',
          'Cinematographer',
          'Client',
          'Collection registrar',
          'Collector',
          'Collotyper',
          'Colorist',
          'Commentator',
          'Commentator for written text',
          'Compiler',
          'Complainant',
          'Complainant-appellant',
          'Complainant-appellee',
          'Composer',
          'Compositor',
          'Conceptor',
          'Conductor',
          'Conservator',
          'Consultant',
          'Consultant to a project',
          'Contestant',
          'Contestant-appellant',
          'Contestant-appellee',
          'Contestee',
          'Contestee-appellant',
          'Contestee-appellee',
          'Contractor',
          'Contributor',
          'Copyright claimant',
          'Copyright holder',
          'Corrector',
          'Correspondent',
          'Costume designer',
          'Court governed',
          'Court reporter',
          'Cover designer',
          'Creator',
          'Curator',
          'Dancer',
          'Data contributor',
          'Data manager',
          'Dedicatee',
          'Dedicator',
          'Defendant',
          'Defendant-appellant',
          'Defendant-appellee',
          'Degree granting institution',
          'Degree supervisor',
          'Delineator',
          'Depicted',
          'Depositor',
          'Designer',
          'Director',
          'Dissertant',
          'Distribution place',
          'Distributor',
          'Donor',
          'Draftsman',
          'Dubious author',
          'Editor',
          'Editor of compilation',
          'Editor of moving image work',
          'Electrician',
          'Electrotyper',
          'Enacting jurisdiction',
          'Engineer',
          'Engraver',
          'Etcher',
          'Event place',
          'Expert',
          'Facsimilist',
          'Field director',
          'Film director',
          'Film distributor',
          'Film editor',
          'Film producer',
          'Filmmaker',
          'First party',
          'Forger',
          'Former owner',
          'Funder',
          'Geographic information specialist',
          'Honoree',
          'Host',
          'Host institution',
          'Illuminator',
          'Illustrator',
          'Inscriber',
          'Instrumentalist',
          'Interviewee',
          'Interviewer',
          'Inventor',
          'Issuing body',
          'Judge',
          'Jurisdiction governed',
          'Laboratory',
          'Laboratory director',
          'Landscape architect',
          'Lead',
          'Lender',
          'Libelant',
          'Libelant-appellant',
          'Libelant-appellee',
          'Libelee',
          'Libelee-appellant',
          'Libelee-appellee',
          'Librettist',
          'Licensee',
          'Licensor',
          'Lighting designer',
          'Lithographer',
          'Lyricist',
          'Manufacture place',
          'Manufacturer',
          'Marbler',
          'Markup editor',
          'Medium',
          'Metadata contact',
          'Metal-engraver',
          'Minute taker',
          'Moderator',
          'Monitor',
          'Music copyist',
          'Musical director',
          'Musician',
          'Narrator',
          'Onscreen presenter',
          'Opponent',
          'Organizer',
          'Originator',
          'Other',
          'Owner',
          'Panelist',
          'Papermaker',
          'Patent applicant',
          'Patent holder',
          'Patron',
          'Performer',
          'Permitting agency',
          'Photographer',
          'Plaintiff',
          'Plaintiff-appellant',
          'Plaintiff-appellee',
          'Platemaker',
          'Praeses',
          'Presenter',
          'Printer',
          'Printer of plates',
          'Printmaker',
          'Process contact',
          'Producer',
          'Production company',
          'Production designer',
          'Production manager',
          'Production personnel',
          'Production place',
          'Programmer',
          'Project director',
          'Proofreader',
          'Provider',
          'Publication place',
          'Publisher',
          'Publishing director',
          'Puppeteer',
          'Radio director',
          'Radio producer',
          'Recording engineer',
          'Recordist',
          'Redaktor',
          'Renderer',
          'Reporter',
          'Repository',
          'Research team head',
          'Research team member',
          'Researcher',
          'Respondent',
          'Respondent-appellant',
          'Respondent-appellee',
          'Responsible party',
          'Restager',
          'Restorationist',
          'Reviewer',
          'Rubricator',
          'Scenarist',
          'Scientific advisor',
          'Screenwriter',
          'Scribe',
          'Sculptor',
          'Second party',
          'Secretary',
          'Seller',
          'Set designer',
          'Setting',
          'Signer',
          'Singer',
          'Sound designer',
          'Speaker',
          'Sponsor',
          'Stage director',
          'Stage manager',
          'Standards body',
          'Stereotyper',
          'Storyteller',
          'Supporting host',
          'Surveyor',
          'Teacher',
          'Technical director',
          'Television director',
          'Television producer',
          'Thesis advisor',
          'Transcriber',
          'Translator',
          'Type designer',
          'Typographer',
          'University place',
          'Videographer',
          'Voice actor',
          'Witness',
          'Wood engraver',
          'Woodcutter',
          'Writer of accompanying material',
          'Writer of added commentary',
          'Writer of added lyrics',
          'Writer of added text',
          'Writer of introduction',
          'Writer of preface',
          'Writer of supplementary textual content']
collection_field_manager = [
  {
    label: 'Identifier',
    system_name: 'identifier',
    is_vocabulary: 0,
    vocabulary: '',
    column_type: 4,
    dropdown_options: '',
    default: 1,
    help_text: '',
    source_type: 'Collection',
    is_required: 0,
    is_repeatable: 1,
    is_public: 1,
    is_custom: 0
  },
  {
    label: 'Creator',
    system_name: 'creator',
    is_vocabulary: 0,
    vocabulary: '',
    column_type: 4,
    dropdown_options: '',
    default: 1,
    help_text: '',
    source_type: 'Collection',
    is_required: 0,
    is_repeatable: 1,
    is_public: 1,
    is_custom: 0
  },
  {
    label: 'Link',
    system_name: 'link',
    is_vocabulary: 0,
    vocabulary: '',
    column_type: 6,
    dropdown_options: '',
    default: 1,
    help_text: '',
    source_type: 'Collection',
    is_required: 0,
    is_repeatable: 1,
    is_public: 1,
    is_custom: 0
  },
  {
    label: 'Date Span',
    system_name: 'date_span',
    is_vocabulary: 0,
    vocabulary: '',
    column_type: 4,
    dropdown_options: '',
    default: 1,
    help_text: '',
    source_type: 'Collection',
    is_required: 0,
    is_repeatable: 1,
    is_public: 1,
    is_custom: 0
  },
  {
    label: 'Extent',
    system_name: 'extent',
    is_vocabulary: 0,
    vocabulary: '',
    column_type: 4,
    dropdown_options: '',
    default: 1,
    help_text: '',
    source_type: 'Collection',
    is_required: 0,
    is_repeatable: 1,
    is_public: 1,
    is_custom: 0
  },
  {
    label: 'Language',
    system_name: 'language',
    is_vocabulary: 0,
    vocabulary: '',
    column_type: 1,
    dropdown_options: '',
    default: 1,
    help_text: '',
    source_type: 'Collection',
    is_required: 0,
    is_repeatable: 1,
    is_public: 1,
    is_custom: 0
  },
  {
    label: 'Conditions Governing Access',
    system_name: 'conditions_governing_access',
    is_vocabulary: 0,
    vocabulary: '',
    column_type: 6,
    dropdown_options: '',
    default: 1,
    help_text: '',
    source_type: 'Collection',
    is_required: 0,
    is_repeatable: 1,
    is_public: 1,
    is_custom: 0
  },
  {
    label: 'Title',
    system_name: 'title',
    is_vocabulary: 0,
    vocabulary: '',
    column_type: 4,
    dropdown_options: '',
    default: 1,
    help_text: '',
    source_type: 'CollectionResource',
    is_required: 0,
    is_repeatable: 1,
    is_public: 1,
    is_custom: 0
  },
  {
    label: 'Preferred Citation',
    system_name: 'preferred_citation',
    is_vocabulary: 0,
    vocabulary: '',
    column_type: 6,
    dropdown_options: '',
    default: 1,
    help_text: '',
    source_type: 'CollectionResource',
    is_required: 0,
    is_repeatable: 1,
    is_public: 1,
    is_custom: 0
  },
  {
    label: 'Source Metadata URI',
    system_name: 'source_metadata_uri',
    is_vocabulary: 0,
    vocabulary: '',
    column_type: 4,
    dropdown_options: '',
    default: 1,
    help_text: '',
    source_type: 'CollectionResource',
    is_required: 0,
    is_repeatable: 1,
    is_public: 1,
    is_custom: 0
  },
  {
    label: 'Duration',
    system_name: 'duration',
    is_vocabulary: 0,
    vocabulary: '',
    column_type: 4,
    dropdown_options: '',
    default: 1,
    help_text: '',
    source_type: 'CollectionResource',
    is_required: 0,
    is_repeatable: 1,
    is_public: 1,
    is_custom: 0
  },
  {
    label: 'Publisher',
    system_name: 'publisher',
    is_vocabulary: 0,
    vocabulary: '',
    column_type: 4,
    dropdown_options: '',
    default: 1,
    help_text: '',
    source_type: 'CollectionResource',
    is_required: 0,
    is_repeatable: 1,
    is_public: 1,
    is_custom: 0
  },
  {
    label: 'Rights Statement',
    system_name: 'rights_statement',
    is_vocabulary: 0,
    vocabulary: '',
    column_type: 6,
    dropdown_options: '',
    default: 1,
    help_text: '',
    source_type: 'CollectionResource',
    is_required: 0,
    is_repeatable: 1,
    is_public: 1,
    is_custom: 0
  },
  {
    label: 'Source',
    system_name: 'source',
    is_vocabulary: 0,
    vocabulary: '',
    column_type: 4,
    dropdown_options: '',
    default: 1,
    help_text: '',
    source_type: 'CollectionResource',
    is_required: 0,
    is_repeatable: 1,
    is_public: 1,
    is_custom: 0
  },
  {
    label: 'Agent',
    system_name: 'agent',
    is_vocabulary: 1,
    vocabulary: agents.to_json,
    column_type: 4,
    dropdown_options: '',
    default: 1,
    help_text: '',
    source_type: 'CollectionResource',
    is_required: 0,
    is_repeatable: 1,
    is_public: 1,
    is_custom: 0
  },
  {
    label: 'Date',
    system_name: 'date',
    is_vocabulary: 1,
    vocabulary: ['issued', 'created', 'captured', 'valid', 'modified', 'other'].to_json,
    column_type: 3,
    dropdown_options: '',
    default: 1,
    help_text: '',
    source_type: 'CollectionResource',
    is_required: 0,
    is_repeatable: 1,
    is_public: 1,
    is_custom: 0
  },
  {
    label: 'Coverage',
    system_name: 'coverage',
    is_vocabulary: 1,
    vocabulary: ['spatial', 'temporal'].to_json,
    column_type: 4,
    dropdown_options: '',
    default: 1,
    help_text: '',
    source_type: 'CollectionResource',
    is_required: 0,
    is_repeatable: 1,
    is_public: 1,
    is_custom: 0
  },
  {
    label: 'Language',
    system_name: 'language',
    is_vocabulary: 1,
    vocabulary: ['primary', 'secondary', 'tertiary', 'other'].to_json,
    column_type: 4,
    dropdown_options: '',
    default: 1,
    help_text: '',
    source_type: 'CollectionResource',
    is_required: 0,
    is_repeatable: 1,
    is_public: 1,
    is_custom: 0
  },
  {
    label: 'Description',
    system_name: 'description',
    is_vocabulary: 1,
    vocabulary: ['general', 'citation', 'summary', 'scope content', 'supplement', 'other', 'abstract'].to_json,
    column_type: 6,
    dropdown_options: '',
    default: 1,
    help_text: '',
    source_type: 'CollectionResource',
    is_required: 0,
    is_repeatable: 1,
    is_public: 1,
    is_custom: 0
  },
  {
    label: 'Format',
    system_name: 'format',
    is_vocabulary: 0,
    vocabulary: '',
    column_type: 4,
    dropdown_options: '',
    default: 1,
    help_text: '',
    source_type: 'CollectionResource',
    is_required: 0,
    is_repeatable: 1,
    is_public: 1,
    is_custom: 0
  },
  {
    label: 'Identifier',
    system_name: 'identifier',
    is_vocabulary: 1,
    vocabulary: ['doi (Digital Objects Identifier)', 'hdl (Handle)', 'isbn (International Standard Book Number)', 'ismn (International Standard Music Number)', 'isrc (International Standard Recording Code)', 'issn (International Standard Serials Number)', 'issue number', 'istc (International Standard Text Code)', 'lccn (Library of Congress Control Number)', 'local', 'matrix number', 'music plate', 'music publisher', 'sici (Serial Item and Contribution Identifier)', 'stock number', 'upc (Universal Product Code)', 'uri (Uniform Resource Identifier)', 'videorecording identifier', 'other'].to_json,
    column_type: 4,
    dropdown_options: '',
    default: 1,
    help_text: '',
    source_type: 'CollectionResource',
    is_required: 0,
    is_repeatable: 1,
    is_public: 1,
    is_custom: 0
  },
  {
    label: 'Relation',
    system_name: 'relation',
    is_vocabulary: 1,
    vocabulary: ['conforms to', 'has format', 'has part', 'has version', 'is format of', 'is part of', 'is referenced by', 'is replaced by', 'is required by', 'is version of', 'other'].to_json,
    column_type: 4,
    dropdown_options: '',
    default: 1,
    help_text: '',
    source_type: 'CollectionResource',
    is_required: 0,
    is_repeatable: 1,
    is_public: 1,
    is_custom: 0
  },
  {
    label: 'Subject',
    system_name: 'subject',
    is_vocabulary: 1,
    vocabulary: ['personal name', 'corporate name', 'meeting name', 'named event', 'chronological term', 'topical term', 'geographic term', 'uncontrolled', 'genre/form', 'other'].to_json,
    column_type: 4,
    dropdown_options: '',
    default: 1,
    help_text: '',
    source_type: 'CollectionResource',
    is_required: 0,
    is_repeatable: 1,
    is_public: 1,
    is_custom: 0
  },
  {
    label: 'Keyword',
    system_name: 'keyword',
    is_vocabulary: 0,
    vocabulary: '',
    column_type: 4,
    dropdown_options: '',
    default: 1,
    help_text: '',
    source_type: 'CollectionResource',
    is_required: 0,
    is_repeatable: 1,
    is_public: 1,
    is_custom: 0
  },
  {
    label: 'Type',
    system_name: 'type',
    is_vocabulary: 0,
    vocabulary: '',
    column_type: 4,
    dropdown_options: '',
    default: 1,
    help_text: '',
    source_type: 'CollectionResource',
    is_required: 0,
    is_repeatable: 1,
    is_public: 1,
    is_custom: 0
  }

]

puts '============================ Plans ============================='
puts '================================================================'
plans = [
  { name: 'Starter', stripe_id: 'aviary-starter-monthly', amount: 9.95, frequency: 1, max_resources: 100 },
  { name: 'Starter', stripe_id: 'aviary-starter-yearly', amount: 95.52, frequency: 2, max_resources: 100 },
  { name: 'Pro', stripe_id: 'aviary-pro-monthly', amount: 99.95, frequency: 1, max_resources: 1000 },
  { name: 'Pro', stripe_id: 'aviary-pro-yearly', amount: 959.52, frequency: 2, max_resources: 1000 },
  { name: 'Business', stripe_id: 'aviary-business-monthly', amount: 399.95, frequency: 1, max_resources: 5000 },
  { name: 'Business', stripe_id: 'aviary-business-yearly', amount: 3839.52, frequency: 2, max_resources: 5000 },
  { name: 'Premium', stripe_id: 'aviary-premium-monthly', amount: 999.95, frequency: 1, max_resources: 25000 },
  { name: 'Premium', stripe_id: 'aviary-premium-yearly', amount: 9599.52, frequency: 2, max_resources: 25000 },
  { name: 'Premium Plus', stripe_id: 'aviary-premium-plus-monthly', amount: 1499.95, frequency: 1, max_resources: 75000 },
  { name: 'Premium Plus', stripe_id: 'aviary-premium-plus-yearly', amount: 14399.52, frequency: 2, max_resources: 75000 },
  { name: 'Premium Max', stripe_id: 'aviary-premium-max-monthly', amount: 1999.95, frequency: 1, max_resources: 150000 },
  { name: 'Premium Max', stripe_id: 'aviary-premium-max-yearly', amount: 19199.52, frequency: 2, max_resources: 150000 },
  { name: 'Enterprise', stripe_id: '', amount: 0, frequency: 3, max_resources: 9999999 },
  { name: 'Pay-as-you-go', stripe_id: 'aviary-pay-as-you-go', amount: 0, frequency: 1, max_resources: 9999999 }
]

plans.each do |plan|
  if Plan.find_by(name: plan[:name], frequency: plan[:frequency]).nil?
    Plan.create(plan)
  end
end
puts '======================== Default User =========================='
puts '================================================================'
user = User.where(email: 'user@demo.com').first_or_initialize
user.first_name = 'AVIARY'
user.last_name = 'User'
user.password = 'demouser'
user.password_confirmation = 'demouser'
user.username = 'demouser'
user.agreement = 1
user.status = true
user.save(validate: false)
user.confirm
puts '==================== Public Organization ======================='
puts '================================================================'
Organization.skip_callback(:create, :before, :create_bucket)
organization = Organization.where(url: 'public').first_or_initialize
organization.user = user
organization.name = 'Public'
organization.storage_type = :free_storage
organization.bucket_name = 'aviary-p_public'
organization.logo_image = open("#{Rails.root}/public/aviary_default_logo.png")
organization.banner_image = open("#{Rails.root}/public/aviary_default_banner.png")
organization.save(validate: false)
Organization.set_callback(:create, :before, :create_bucket)
org_user = user.organization_users.where(organization_id: organization.id, role_id: Role.role_organization_owner.id).first_or_initialize
org_user.status = true
org_user.save

plan = Plan.find_by(name: 'Premium Max', frequency: Plan::Frequency::YEARLY)
end_time = Time.now + 1.year

subscription = Subscription.where(plan_id: plan.id, organization_id: organization.id).first_or_initialize

subscription.plan = plan
subscription.organization = organization
subscription.start_date = Time.now
subscription.renewal_date = end_time
subscription.current_price = 0.0
subscription.status = :active
subscription.save(validate: false)

puts '==================== Default Collection ========================'
puts '================================================================'
collection = organization.collections.new
collection.title = 'How to Aviary'
collection.about = 'This series of quick videos will introduce you to the basics of Aviary, AVP’s next-generation platform for streaming audio and video content. '
collection.is_featured = true
collection.is_public = true
collection.image = open("#{Rails.root}/public/banner.png")
collection.favicon = open("#{Rails.root}/public/fav.ico")
collection.save
collection_field_sort = Aviary::FieldManagement::OrganizationFieldManager.new.organization_field_settings(collection.organization, nil, 'collection_fields', 'sort_order')
metadata = JSON.parse({
                        "Creator": [
                          {
                            "value": "AVP"
                          }
                        ],
                        "Language": [
                          {
                            "value": "English, Spanish"
                          }
                        ]
                      }.to_json)
updated_field_values = {}
collection_field_sort.each do |(system_name, value)|
  if value['label'].present? && metadata.present? && metadata[value['label']]
    if updated_field_values[system_name].nil?
      updated_field_values[system_name] = { field_id: system_name, values: [] }
    end
    metadata[value['label']].each do |meta|
      updated_field_values[system_name][:values] << {
        value: meta['value'].to_s.strip, vocab_value: ''
      }
    end
  end
end
collection_field_value = CollectionFieldsAndValue.find_or_create_by(collection_id: collection.id)
collection_field_value.collection_field_values = updated_field_values
collection_field_value.save unless updated_field_values.nil?
puts '====================== Default Resource ========================'
puts '================================================================'
resource = collection.collection_resources.new
resource.title = 'Intro to Aviary'
resource.is_featured = true
resource.access = 'access_restricted'
resource.status = true
resource.save

resource_metadata = JSON.parse({
                                 "Date": [
                                   {
                                     "value": "2019",
                                     "vocabulary": "created"
                                   }
                                 ],
                                 "Agent": [
                                   {
                                     "value": "AVP",
                                     "vocabulary": "Creator"
                                   }
                                 ],
                                 "Preferred Citation": [
                                   {
                                     "value": "Aviary Introduction, AVP, 2019",

                                   }
                                 ],
                                 "Rights Statement": [
                                   {
                                     "value": "CC BY 4.0",

                                   }
                                 ],
                                 "Publisher": [
                                   {
                                     "value": "AVP",

                                   }
                                 ],
                                 "Keyword": [
                                   {
                                     "value": "multi-tenant",

                                   },
                                   {
                                     "value": "audiovisual search",

                                   },
                                   {
                                     "value": "synced transcripts",

                                   },
                                   {
                                     "value": "synced indexes",

                                   },
                                   {
                                     "value": "audiovisual",

                                   },
                                   {
                                     "value": "media files",

                                   }

                                 ]
                               }.to_json)

updated_resource_field_values = {}
resource_metadata.each do |(system_name, value)|
  k = system_name.gsub(' ', '_').downcase
  updated_resource_field_values[k] = { system_name: k, values: [] }
  value.each do |v|
    v = v.is_a?(Hash) ? [v] : v
    v.each do |single|
      updated_resource_field_values[k][:values] << { value: single['value'].to_s.strip, vocab_value: single['vocabulary'].present? ? single['vocabulary'] : '' }
    end
  end

end

ResourceDescriptionValue.find_by(collection_resource_id: resource.id)&.destroy
resource_description_value = ResourceDescriptionValue.find_or_create_by(collection_resource_id: resource.id)
resource_description_value.resource_field_values = updated_resource_field_values
resource_description_value.save
resource.update(updated_at: Time.now)
resource = CollectionResource.find(resource.id)
resource.reindex_collection_resource
puts '======================== Default Media ========================='
puts '================================================================'
url = 'https://d9jk7wjtjpu5g.cloudfront.net/aviary-intro.mp4'

param_collection_resource = { title: 'AviaryDemo.mp4', duration: 84, embed_type: 0 }
embed_name = CollectionResourceFile.embed_type_name(param_collection_resource[:embed_type].to_i)
param_collection_resource = { title: 'AviaryDemo.mp4', duration: 84, embed_type: 0 }
video_metadata = Aviary::ExtractVideoMetadata::VideoEmbed.new(embed_name, url, param_collection_resource).metadata

thumbnail = ''

embed_code_hash = { embed_code: video_metadata['url'], embed_type: param_collection_resource[:embed_type],
                    resource_file_file_name: video_metadata['title'], embed_content_type: video_metadata['content_type'], thumbnail: thumbnail, duration: video_metadata['duration'] }
embed_code_hash[:file_display_name] = video_metadata['title'] if param_collection_resource[:embed_type].to_i.zero?

media_file = resource.collection_resource_files.create(embed_code_hash.merge!(sort_order: 1))

puts '====================== Default Transcript ======================'
puts '================================================================'
transcript = media_file.file_transcripts.new
transcript.user = media_file.collection_resource.collection.organization.user
transcript.title = 'WHISPER_AviaryDemo'
transcript.language = 'en'
transcript.is_public = true
transcript.sort_order = 1
transcript.is_caption = true
transcript.description = ''
transcript.associated_file = open("#{Rails.root}/spec/fixtures/WHISPER_AviaryDemo.webvtt")
transcript.save

Aviary::IndexTranscriptManager::TranscriptManager.new.process(transcript, 1)

puts '======================== Default Index ========================='
puts '================================================================'
index = media_file.file_indexes.new
index.user = media_file.collection_resource.collection.organization.user
index.title = 'Assembly_AI_AviaryDemo'
index.language = 'en'
index.is_public = true
index.sort_order = 1
index.description = ''
index.associated_file = open("#{Rails.root}/spec/fixtures/Assembly_AI_AviaryDemo.webvtt")
index.save

Aviary::IndexTranscriptManager::IndexManager.new.process(index, true)