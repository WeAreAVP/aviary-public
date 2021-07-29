# BasePresenter
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class BasePresenter < SimpleDelegator
  def initialize(model, view)
    @model = model
    @view = view
    super(@model)
  end

  def h
    @view
  end
end
