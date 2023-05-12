class AddEthnographicAndLcshThesaurusToAllOrgs < ActiveRecord::Migration[6.1]
  def up
    Organization.all.each do  |org|
      user = org.user if org.user.present?
      user||= User.first
      lcsh = ::Thesaurus::Thesaurus.where(title: 'LCSH', parent_id: 0, type_of_thesaurus: 0).try(:first)
      ethno = ::Thesaurus::Thesaurus.where(title: 'Ethnographic Thesaurus', parent_id: 0, type_of_thesaurus: 0).try(:first)
      return unless lcsh.present?
      test = ::Thesaurus::Thesaurus.create(
        organization: org,
        title: lcsh.title,
        description: lcsh.description.present? ? lcsh.description : ' none ',
        status: lcsh.status,
        number_of_terms: lcsh.number_of_terms,
        type_of_thesaurus: 1,
        created_by_id: user.id,
        updated_by_id: user.id,
        created_at: Time.now,
        updated_at: Time.now,
        parent_id: lcsh.id
      )
      test.save

      return unless ethno.present?
      ethno_test = ::Thesaurus::Thesaurus.create(
        organization: org,
        title: ethno.title,
        description: ethno.description.present? ? ethno.description : ' none ',
        status: ethno.status,
        number_of_terms: ethno.number_of_terms,
        type_of_thesaurus: 1,
        created_by_id: user.id,
        updated_by_id: user.id,
        created_at: Time.now,
        updated_at: Time.now,
        parent_id: ethno.id
      )
      ethno_test.save
    end
  end

  def down
    ::Thesaurus::Thesaurus.where.not("title IN ('LCSH', 'Ethnographic Thesaurus') AND parent_id = 0 AND type_of_thesaurus = 0").destroy_all  
  end
end
