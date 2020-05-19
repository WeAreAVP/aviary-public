### Delete Duplicate User Level Permission group and related access request         
        
        duplicates = PermissionGroup.find_by_sql('SELECT *, count(*) FROM aviary.permission_groups where group_type = 1 AND organization_id=5 GROUP BY permission_object Having count(*) > 1')
        duplicates.each do |duplicate|
            list_pg = PermissionGroup.where(group_name: duplicate.group_name).order('id DESC')
            check = 1
            list_pg.each do |pg|
                if check == 1
                    check = 0
                        puts "don't delete #{pg.id}"
                else
                    pg.request_access.destroy if pg.request_access.present?
                    pg.destroy
                end
            end
        end