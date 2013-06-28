module ImportHelper

  def diff_output(target_p, source_p, attr)
    if attr == 'assignee'
      if target_p.user == source_p.user
        if target_p.user.blank?
          '-'
        else
          target_p.user.name
        end
      elsif confirmed?
        target_p.user ||= User.new
        "<span style='color:red;'>#{target_p.user.name}</span>"
      else
        target_p.user ||= User.new
        source_p.user ||= User.new
        "<span style='color:red;'>#{source_p.user.name} => #{target_p.user.name}</span>"
      end
    elsif attr== 'status'
      if target_p.status == source_p.status
        if target_p.status.blank?
          '-'
        else
          target_p.status.name
        end
      elsif confirmed?
        target_p.status ||= Status.new
        "<span style='color:red;'>#{target_p.status.name}</span>"
      else
        target_p.status ||= Status.new
        source_p.status ||= Status.new
        "<span style='color:red;'>#{source_p.status.name} => #{target_p.status.name}</span>"
      end
    elsif attr== 'tags'
      if target_p.tags == source_p.tags
        if target_p.tags.blank?
          '-'
        else
          str = ""
          str += display_tags(target_p.tags)
          str
        end
      elsif confirmed?
        target_p.tags ||= []
        str = "<span style='color:red;'>"
        str += display_tags(target_p.tags)
        str += "</span>"
        str
      else
        target_p.tags ||= []
        source_p.tags ||= []
        "<span style='color:red;'>#{display_tags(source_p.tags)} => #{display_tags(target_p.tags)}</span>"
      end
    elsif attr== 'notes'
      if target_p.notes == source_p.notes
        if target_p.notes = nil
          ' - '
        else
          '[NOT CHANGED]'
        end
      elsif confirmed?
        target_p.notes ||= ""
        "<span style='color:red;'>#{truncate_u(target_p.notes(:plain))}</span>"
      else
        source_p.notes ||= ""
        target_p.notes ||= ""
        "<span style='color:red;'>#{truncate_u(source_p.notes(:plain))} => #{truncate_u(target_p.notes(:plain))}</span>"
      end
    elsif target_p.read_attribute(attr) == source_p.read_attribute(attr)
      target_p.read_attribute(attr)
    elsif confirmed?
      target_p[attr] ||= ''
      "<span style='color:red;'>#{target_p.read_attribute(attr)}</span>"
    else
      source_p[attr] ||= ''
      target_p[attr] ||= ''
      "<span style='color:red;'>#{source_p.read_attribute(attr)} => #{target_p.read_attribute(attr)}</span>"
    end
  end

end
