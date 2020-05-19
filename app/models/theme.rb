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
      %i[9px 10px 11px 12px 13px 14px 15px 16px 17px 18px 19px 20px 21px 22px 23px]
    end

    def self.for_select
      FONTFAMILY.invert.to_a
    end

    def self.for_select_bg_type
      BGIMAGETYPE.invert.to_a
    end
  end
end
