def set_session(org_name)
  visit root_path
  find('body').has_content? 'My Organization'
  click_on 'My Organization'
  click_on org_name
end