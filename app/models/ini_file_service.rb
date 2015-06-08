class IniFileService

	def get_ini_options(package)
    branch = @package.task.primary_os_advisory_tag.candidate_tag
    ini_file = get_file_content_from_rpm_repo(@package.name, branch,
                                              "#{@package.name}.ini")

    if ini_file.blank?
      if package.ini_file.blank?
        @maven_group_artifact = ''
        @build_requires = ''
        @goals = ''
        @profiles = ''
        @properties = ''
        @maven_options = ''
        @envs = ''
        @jvm_options = ''
      else
        data = parse_ini_file(@package.ini_file)
        section = data.keys[0]
        config = data[section]
        @maven_group_artifact = section
        @build_requires = replace_newline_to_whitespace(config['buildrequires'])
        @goals = replace_newline_to_whitespace(config['goals'])
        @profiles = replace_newline_to_whitespace(config['profiles'])
        @properties = replace_newline_to_whitespace(config['properties'])
        @maven_options = replace_newline_to_whitespace(config['maven_options'])
        @envs = replace_newline_to_whitespace(config['envs'])
        @jvm_options = replace_newline_to_whitespace(config['jvm_options'])
      end
    else
      if !@package.ini_file.blank?
        if @package.ini_file_sha == Digest::SHA1.hexdigest ini_file
          data = parse_ini_file(@package.ini_file)
        else
          data = parse_ini_file(ini_file)
        end
      else
        data = parse_ini_file(ini_file)
      end

      section = data.keys[0]
      config = data[section]
      @maven_group_artifact = section
      @build_requires = replace_newline_to_whitespace(config['buildrequires'])
      @goals = replace_newline_to_whitespace(config['goals'])
      @profiles = replace_newline_to_whitespace(config['profiles'])
      @properties = replace_newline_to_whitespace(config['properties'])
      @maven_options = replace_newline_to_whitespace(config['maven_options'])
      @envs = replace_newline_to_whitespace(config['envs'])
      @jvm_options = replace_newline_to_whitespace(config['jvm_options'])
    end
	end

end
