import ConfigParser
import json
import re
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
        if "\n" in value:
            items = value.split("\n")
            new_items = []

            for item in items:
                # if item contains whitespace
                if re.search(r"\s", item.strip()) and not re.search("=\"", item.strip()):
                    item = item.replace("=", "=\"") + '"'
                new_items.append(item)
            value = "\n".join(new_items)
        json_to_return[section][key] = value

json_data = json.dumps(json_to_return)
print json_data
