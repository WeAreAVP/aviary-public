require 'rails_helper'
require 'spec_helper'

describe "Test CustomFields with dummy models" do
  module MyModule; end

  with_model :Car do
    # The table block (and an options hash) is passed to ActiveRecord migration’s `create_table`.
    table do |t|
      t.string :make
      t.string :model
      t.integer :year
      t.timestamps null: false
    end

    # The model block is the ActiveRecord model’s class body.
    model do
      include MyModule
      custom_fields?
      validates_presence_of :make, :model, :year

      def self.some_class_method
        'chunky'
      end

      def some_instance_method
        'bacon'
      end
    end
  end

  with_model :Author do
    # The table block (and an options hash) is passed to ActiveRecord migration’s `create_table`.
    table do |t|
      t.string :name
      t.timestamps null: false
    end

    # The model block is the ActiveRecord model’s class body.
    model do
      include MyModule
      has_many :book, dependent: :destroy
      custom_fields?
      validates_presence_of :name
      attr_accessor :dynamic_initializer

      def init_dynamic_initializer
        @dynamic_initializer = {
            field_types: %w[Author Book]
        }
      end
    end
  end

  with_model :Book do
    # The table block (and an options hash) is passed to ActiveRecord migration’s `create_table`.
    table do |t|
      t.integer "author_id"
      t.string :name
      t.timestamps null: false
      t.index ["author_id"], name: "a_book_index"
    end

    # The model block is the ActiveRecord model’s class body.
    model do
      include MyModule
      belongs_to :author
      custom_fields?
      validates_presence_of :name
      attr_accessor :dynamic_initializer

      def init_dynamic_initializer
        @dynamic_initializer = {
            parent_entity: author
        }
      end
    end
  end

  describe "Car Custom Fields Test Cases" do
    let!(:car1) {Car.new}
    let(:price) {build(:fields, label:'Price', system_name: 'price', source_type: car1.class.name)}
    let(:notes) {build(:fields, label:'Notes', system_name: 'notes', source_type: car1.class.name)}
    let(:type) {build(:fields,:is_dropdown, dropdown_options: %w[New Used], label:'Type', system_name: 'type', source_type: car1.class.name)}
    let(:identifier) {build(:fields,:has_vocabulary, label:'Identifier', system_name: 'identifier', source_type: car1.class.name)}
    before do
      car1.make = "Honda"
      car1.model = "Civic"
      car1.year = 2019
      car1.save
    end
    it "has some make, model and year" do
      expect(car1.make).to eq "Honda"
      expect(car1.model).to eq "Civic"
      expect(car1.year).to eq 2019
    end
    it "has no default system field by default" do
      expect(car1.dynamic_attributes['fields'].length).to eq(0)
    end

    context "Add new custom field" do
      it "should have price field" do
        car1.create_update_dynamic(price.as_json.symbolize_keys)
        price_field = car1.dynamic_attributes['fields'].first
        expect(price_field.id).to eq(1)
      end
      it "should have notes field" do
         car1.create_update_dynamic(notes.as_json.symbolize_keys)
         notes_field = car1.dynamic_attributes['fields'].first
        expect(notes_field.id).to eq(1)
      end
      it "should have dropdown field" do
        car1.create_update_dynamic(type.as_json.symbolize_keys)
        type = car1.dynamic_attributes['fields'].first
        expect(type.id).to eq(1)
      end
    end

    context "Delete Custom Field" do
      it "should delete price field" do
        price_id = car1.create_update_dynamic(price.as_json.symbolize_keys)
        car1.create_update_dynamic(notes.as_json.symbolize_keys)
        expect(car1.dynamic_attributes['fields'].length).to eq 2
        expect(car1.delete_dynamic(price_id)).to be_truthy
        expect(car1.dynamic_attributes['fields'].length).to eq 1
      end
    end

    context "Custom Fields Setting" do
      it "should reorder custom fields" do
        car1.create_update_dynamic(price.as_json.symbolize_keys)
        car1.create_update_dynamic(notes.as_json.symbolize_keys)
        old_settings = car1.dynamic_attributes['settings'][car1.class.name]
        updated_settings = [old_settings[1], old_settings[0]]
        expect(car1.update_field_settings(updated_settings)).to be_truthy
        new_settings = car1.dynamic_attributes['settings'][car1.class.name]
        expect(new_settings).to_not eq(old_settings)
      end

      it "should update tombstone setting of field" do
        car1.create_update_dynamic(price.as_json.symbolize_keys)
        price_setting = car1.dynamic_attributes['settings'][car1.class.name][0]
        price_setting["is_tombstone"] = true
        expect(car1.update_field_settings([price_setting])).to be_truthy
        new_settings = car1.dynamic_attributes['settings'][car1.class.name]
        expect(new_settings[0]["is_tombstone"]).to be_truthy
      end

      it "should update visible setting of field" do
        car1.create_update_dynamic(price.as_json.symbolize_keys)
        price_setting = car1.dynamic_attributes['settings'][car1.class.name][0]
        price_setting["is_visible"] = false
        expect(car1.update_field_settings([price_setting])).to be_truthy
        new_settings = car1.dynamic_attributes['settings'][car1.class.name]
        expect(new_settings[0]["is_visible"]).to be_falsy
      end
    end

    context "Custom Field Values" do
      it "should have custom field(price) value" do
        car1.create_update_dynamic(price.as_json.symbolize_keys)
        price_before = car1.custom_field_value(price.system_name)[0]["value"]
        expect(price_before).to eq("")
        price_value = [{value: 321, value_vocab: ''}]
        expect(car1.update_field_value(price.system_name, price_value)).to be_truthy
        price_after = car1.custom_field_value(price.system_name)[0]["value"]
        expect(price_after.to_i).to eq(321)
        expect(car1.custom_1[0]["value"].to_i).to eq(321)
      end

      it "can update values in bulk" do
        price_id = car1.create_update_dynamic(price.as_json.symbolize_keys)
        notes_id = car1.create_update_dynamic(notes.as_json.symbolize_keys)
        values_fixture = [{field_id: price_id, values: [{value: 1123, value_vocab: ''}]}, {field_id: notes_id, values: [{value: 'test notes', value_vocab: ''}]}]
        expect(car1.batch_update_values(values_fixture)).to be_truthy
        price_value = car1.custom_field_value(price.system_name)[0]["value"]
        notes_value = car1.custom_field_value(notes.system_name)[0]["value"]
        expect(price_value.to_i).to eq(1123)
        expect(notes_value).to eq('test notes')
      end
    end

    context "Custom Field Vocabulary" do
      it "vocabulary already existed" do
        identifier_id = car1.create_update_dynamic(identifier.as_json.symbolize_keys)
        expect(CustomFields::Field.create_or_update_vocabularies(identifier_id, "vocab1")).to be_nil
      end
      it "new vocabulary term added" do
        identifier_id = car1.create_update_dynamic(identifier.as_json.symbolize_keys)
        expect(CustomFields::Field.create_or_update_vocabularies(identifier_id, "vocab test")).to be_truthy
      end
    end

  end

  describe "Check Parent object has child settings" do
    let!(:author) {Author.new}
    let(:book1) {Book.new}
    let(:book2) {Book.new}
    let(:pages) {build(:fields, label:'Pages', system_name: 'pages', source_type: book1.class.name)}
    context "Author object" do
      it "should have settings of Book" do
        settings = author.dynamic_attributes['settings']
        expect(settings.key? ("Book")).to be_truthy
      end

      it "should have default/system fields" do
        settings = author.dynamic_attributes['settings']
        expect(settings.key? ("Author")).to be_truthy
        expect(settings["Author"].length).to eq(3)

      end
    end

    context "Add custom field in Book object" do
      it "should have default fields settings" do
        author.name = "Rimsha"
        author.save
        book1.name = "book 1"
        book1.author = author
        book1.save
        settings = author.dynamic_attributes['settings']
        expect(settings.key? ("Book")).to be_truthy
        expect(settings["Book"].length).to eq(3)
      end

      it "should have pages field added in author object" do
        author.name = "Rimsha"
        author.save
        book1.name = "book 1"
        book1.author = author
        book1.save
        expect(author.create_update_dynamic(pages.as_json.symbolize_keys)).to be_a_kind_of(Integer)
        settings = book1.dynamic_attributes['settings']
        expect(settings.key? ("Book")).to be_truthy
        expect(settings["Book"].length).to eq(4)
      end
    end
  end
end
