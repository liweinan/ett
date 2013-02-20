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
    elsif attr== 'label'
      if target_p.label == source_p.label
        if target_p.label.blank?
          '-'
        else
          target_p.label.name
        end
      elsif confirmed?
        target_p.label ||= Label.new
        "<span style='color:red;'>#{target_p.label.name}</span>"
      else
        target_p.label ||= Label.new
        source_p.label ||= Label.new
        "<span style='color:red;'>#{source_p.label.name} => #{target_p.label.name}</span>"
      end
    elsif attr== 'marks'
      if target_p.marks == source_p.marks
        if target_p.marks.blank?
          '-'
        else
          str = ""
          str += display_marks(target_p.marks)
          str
        end
      elsif confirmed?
        target_p.marks ||= []
        str = "<span style='color:red;'>"
        str += display_marks(target_p.marks)
        str += "</span>"
        str
      else
        target_p.marks ||= []
        source_p.marks ||= []
        "<span style='color:red;'>#{display_marks(source_p.marks)} => #{display_marks(target_p.marks)}</span>"
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
