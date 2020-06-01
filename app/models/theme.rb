# Theme model
class Theme < ApplicationRecord
  # Font handler
  class FontHandler
    ARIAL = 'arial'.freeze
    CALIBRI = 'calibri'.freeze
    DEFAULT = 'default'.freeze
    BGIMAGE = 1
    BGCOLOR = 2
    FONTFAMILY = { DEFAULT => 'Aviary Default Font', ARIAL => 'Arial', CALIBRI => 'Calibri' }.freeze
    BGIMAGETYPE = { BGIMAGE => 'Background Image', BGCOLOR => 'Background Color' }.freeze

    def self.font_sizes
      %i[20px 21px 22px 23px 24px 25px 26px 27px 28px 29px 30px]
    end

    def self.for_select
      FONTFAMILY.invert.to_a
    end

    def self.for_select_bg_type
      BGIMAGETYPE.invert.to_a
    end
  end
end
