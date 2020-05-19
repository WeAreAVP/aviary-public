def selectize(id, value)
  page.execute_script %Q{
var $select = $("#{id}").selectize();
var selectize = $select[0].selectize;
selectize.setValue(selectize.search("#{value}").items[0].id);
}
end