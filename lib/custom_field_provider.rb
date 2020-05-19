# CustomFieldProvider
class CustomFieldProvider
  # Constructor will receive an instance to which dynamic attributes are added
  def initialize(model)
    @model = model
  end

  # This method has to return array of dynamic field definitions.
  # You can get it from the configuration file, DB, etc., depending on your app logic
  def call
    dates = %w[issued created captured valid modified other]
    coverage = %w[spatial temporal]
    language = %w[primary secondary tertiary other]
    description = ['general', 'citation', 'summary', 'scope content', 'supplement', 'other', 'abstract']
    identifier = ['doi (Digital Objects Identifier)', 'hdl (Handle)', 'isbn (International Standard Book Number)',
                  'ismn (International Standard Music Number)', 'isrc (International Standard Recording Code)',
                  'issn (International Standard Serials Number)', 'issue number', 'istc (International Standard Text Code)',
                  'lccn (Library of Congress Control Number)', 'local', 'matrix number', 'music plate', 'music publisher',
                  'sici (Serial Item and Contribution Identifier)', 'stock number', 'upc (Universal Product Code)',
                  'uri (Uniform Resource Identifier)', 'videorecording identifier', 'other']
    relation = ['conforms to', 'has format', 'has part', 'has version', 'is format of', 'is part of', 'is referenced by', 'is replaced by', 'is required by', 'is version of', 'other']
    subject = ['personal name', 'corporate name', 'meeting name', 'named event', 'chronological term', 'topical term', 'geographic term', 'uncontrolled', 'genre/form', 'other']
    agents = ['Abridger', 'Actor', 'Adapter', 'Addressee', 'Analyst', 'Animator', 'Annotator', 'Appellant', 'Appellee', 'Applicant', 'Architect',
              'Arranger', 'Art copyist', 'Art director', 'Artist', 'Artistic director', 'Assignee', 'Associated name', 'Attributed name', 'Auctioneer', 'Author',
              'Author in quotations or text abstracts', 'Author of afterword, colophon, etc.', 'Author of dialog', 'Author of introduction, etc.',
              'Autographer', 'Bibliographic antecedent', 'Binder', 'Binding designer', 'Blurb writer', 'Book designer', 'Book producer',
              'Bookjacket designer', 'Bookplate designer', 'Bookseller', 'Braille embosser', 'Broadcaster', 'Calligrapher', 'Cartographer',
              'Caster', 'Censor', 'Choreographer', 'Cinematographer', 'Client', 'Collection registrar', 'Collector', 'Collotyper', 'Colorist',
              'Commentator', 'Commentator for written text', 'Compiler', 'Complainant', 'Complainant-appellant', 'Complainant-appellee',
              'Composer', 'Compositor', 'Conceptor', 'Conductor', 'Conservator', 'Consultant', 'Consultant to a project', 'Contestant',
              'Contestant-appellant', 'Contestant-appellee', 'Contestee', 'Contestee-appellant', 'Contestee-appellee', 'Contractor', 'Contributor',
              'Copyright claimant', 'Copyright holder', 'Corrector', 'Correspondent', 'Costume designer', 'Court governed', 'Court reporter',
              'Cover designer', 'Creator', 'Curator', 'Dancer', 'Data contributor', 'Data manager', 'Dedicatee', 'Dedicator', 'Defendant',
              'Defendant-appellant', 'Defendant-appellee', 'Degree granting institution', 'Degree supervisor', 'Delineator', 'Depicted',
              'Depositor', 'Designer', 'Director', 'Dissertant', 'Distribution place', 'Distributor', 'Donor', 'Draftsman', 'Dubious author',
              'Editor', 'Editor of compilation', 'Editor of moving image work', 'Electrician', 'Electrotyper', 'Enacting jurisdiction',
              'Engineer', 'Engraver', 'Etcher', 'Event place', 'Expert', 'Facsimilist', 'Field director', 'Film director', 'Film distributor',
              'Film editor', 'Film producer', 'Filmmaker', 'First party', 'Forger', 'Former owner', 'Funder', 'Geographic information specialist',
              'Honoree', 'Host', 'Host institution', 'Illuminator', 'Illustrator', 'Inscriber', 'Instrumentalist', 'Interviewee', 'Interviewer',
              'Inventor', 'Issuing body', 'Judge', 'Jurisdiction governed', 'Laboratory', 'Laboratory director', 'Landscape architect',
              'Lead', 'Lender', 'Libelant', 'Libelant-appellant', 'Libelant-appellee', 'Libelee', 'Libelee-appellant', 'Libelee-appellee',
              'Librettist', 'Licensee', 'Licensor', 'Lighting designer', 'Lithographer', 'Lyricist', 'Manufacture place', 'Manufacturer',
              'Marbler', 'Markup editor', 'Medium', 'Metadata contact', 'Metal-engraver', 'Minute taker', 'Moderator', 'Monitor', 'Music copyist',
              'Musical director', 'Musician', 'Narrator', 'Onscreen presenter', 'Opponent', 'Organizer', 'Originator', 'Other', 'Owner',
              'Panelist', 'Papermaker', 'Patent applicant', 'Patent holder', 'Patron', 'Performer', 'Permitting agency', 'Photographer',
              'Plaintiff', 'Plaintiff-appellant', 'Plaintiff-appellee', 'Platemaker', 'Praeses', 'Presenter', 'Printer', 'Printer of plates',
              'Printmaker', 'Process contact', 'Producer', 'Production company', 'Production designer', 'Production manager', 'Production personnel',
              'Production place', 'Programmer', 'Project director', 'Proofreader', 'Provider', 'Publication place', 'Publisher', 'Publishing director',
              'Puppeteer', 'Radio director', 'Radio producer', 'Recording engineer', 'Recordist', 'Redaktor', 'Renderer', 'Reporter',
              'Repository', 'Research team head', 'Research team member', 'Researcher', 'Respondent', 'Respondent-appellant', 'Respondent-appellee',
              'Responsible party', 'Restager', 'Restorationist', 'Reviewer', 'Rubricator', 'Scenarist', 'Scientific advisor', 'Screenwriter',
              'Scribe', 'Sculptor', 'Second party', 'Secretary', 'Seller', 'Set designer', 'Setting', 'Signer', 'Singer', 'Sound designer',
              'Speaker', 'Sponsor', 'Stage director', 'Stage manager', 'Standards body', 'Stereotyper', 'Storyteller', 'Supporting host',
              'Surveyor', 'Teacher', 'Technical director', 'Television director', 'Television producer', 'Thesis advisor', 'Transcriber',
              'Translator', 'Type designer', 'Typographer', 'University place', 'Videographer', 'Voice actor', 'Witness', 'Wood engraver',
              'Woodcutter', 'Writer of accompanying material', 'Writer of added commentary', 'Writer of added lyrics', 'Writer of added text',
              'Writer of introduction', 'Writer of preface', 'Writer of supplementary textual content']
    case @model
    when Collection
      [
        CustomFields::FieldDefinition.new('identifier', column_type: 4, source_type: 'Collection'),
        CustomFields::FieldDefinition.new('creator', column_type: 4, source_type: 'Collection'),
        CustomFields::FieldDefinition.new('link', column_type: 6, source_type: 'Collection'),
        CustomFields::FieldDefinition.new('date_span', column_type: 4, source_type: 'Collection'),
        CustomFields::FieldDefinition.new('extent', column_type: 4, source_type: 'Collection'),
        CustomFields::FieldDefinition.new('language', column_type: 1, source_type: 'Collection'),
        CustomFields::FieldDefinition.new('conditions_governing_access', column_type: 6, source_type: 'Collection'),
        CustomFields::FieldDefinition.new('title', column_type: 4, source_type: 'CollectionResource'),
        CustomFields::FieldDefinition.new('preferred_citation', column_type: 6, default: 1, help_text: '', source_type: 'CollectionResource'),
        CustomFields::FieldDefinition.new('source_metadata_uri', label: 'Source Metadata URI', column_type: 4, source_type: 'CollectionResource'),
        CustomFields::FieldDefinition.new('duration', column_type: 4, source_type: 'CollectionResource'),
        CustomFields::FieldDefinition.new('publisher', column_type: 4, source_type: 'CollectionResource'),
        CustomFields::FieldDefinition.new('rights_statement', column_type: 6, source_type: 'CollectionResource'),
        CustomFields::FieldDefinition.new('source', column_type: 4, source_type: 'CollectionResource'),
        CustomFields::FieldDefinition.new('agent', is_vocabulary: 1, column_type: 4, vocabulary: agents.to_json, source_type: 'CollectionResource'),
        CustomFields::FieldDefinition.new('date', is_vocabulary: 1, column_type: 3, vocabulary:  dates.to_json, source_type: 'CollectionResource'),
        CustomFields::FieldDefinition.new('coverage', is_vocabulary: 1, column_type: 4, vocabulary: coverage.to_json, source_type: 'CollectionResource'),
        CustomFields::FieldDefinition.new('language', is_vocabulary: 1, column_type: 4, vocabulary: language.to_json, source_type: 'CollectionResource'),
        CustomFields::FieldDefinition.new('description', is_vocabulary: 1, column_type: 6, vocabulary: description.to_json, source_type: 'CollectionResource'),
        CustomFields::FieldDefinition.new('format', column_type: 4, source_type: 'CollectionResource'),
        CustomFields::FieldDefinition.new('identifier', is_vocabulary: 1, column_type: 4, vocabulary: identifier.to_json, source_type: 'CollectionResource'),
        CustomFields::FieldDefinition.new('relation', is_vocabulary: 1, column_type: 4, vocabulary: relation.to_json, source_type: 'CollectionResource'),
        CustomFields::FieldDefinition.new('subject', is_vocabulary: 1, column_type: 4, vocabulary: subject.to_json, source_type: 'CollectionResource'),
        CustomFields::FieldDefinition.new('keyword', column_type: 4, source_type: 'CollectionResource'),
        CustomFields::FieldDefinition.new('type', column_type: 4, source_type: 'CollectionResource')
      ]
    else
      []
    end
  end
end
