import ConfigParser
import json
import StringIO
import sys

ini_data = sys.argv[1]

ini_fp = StringIO.StringIO(ini_data)

config_parser = ConfigParser.RawConfigParser()
config_parser.readfp(ini_fp)

sections = config_parser.sections()

json_to_return = {}

for section in sections:
    json_to_return[section] = {}

    data_from_section = config_parser.items(section)

    for key, value in data_from_section:
        json_to_return[section][key] = value
        
json_data = json.dumps(json_to_return)

print json_data
