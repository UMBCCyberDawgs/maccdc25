import os, csv

SOURCE_CSV = "2025 MACCDC Services - Export-Safe.csv"
OUTPUT_FILE = "paloscript_rules.txt"
PATTERN = {"name": 0, "desc": 1, "action": 2, "from": 3, "to": 4, "source": 5, "dest": 6, "profile": 7, "apps": 8}

with open(OUTPUT_FILE, "w") as f:
    f.write('configure\n')
    f.write('\n')
    with open(SOURCE_CSV) as stream:
        reader = csv.reader(stream)
        for row in reader:
            f.write(f'set rulebase security rules {row[PATTERN["name"]]} profile-setting group {row[PATTERN["profile"]]}\n')
            f.write('\n')
            f.write(f'set rulebase security rules {row[PATTERN["name"]]} description "{row[PATTERN["desc"]]}"\n')
            f.write('\n')
            f.write(f'set rulebase security rules {row[PATTERN["name"]]} action {row[PATTERN["action"]]}\n')
            f.write('\n')
            f.write(f'set rulebase security rules {row[PATTERN["name"]]} service application-default\n')
            f.write('\n')
            f.write(f'set rulebase security rules {row[PATTERN["name"]]} from [ {row[PATTERN["from"]]} ]\n')
            f.write('\n')
            f.write(f'set rulebase security rules {row[PATTERN["name"]]} to [ {row[PATTERN["to"]]} ]\n')
            f.write('\n')
            f.write(f'set rulebase security rules {row[PATTERN["name"]]} source [ {row[PATTERN["source"]]} ]\n')
            f.write('\n')
            f.write(f'set rulebase security rules {row[PATTERN["name"]]} destination [ {row[PATTERN["dest"]]} ]\n')
            f.write('\n')
            f.write(f'set rulebase security rules {row[PATTERN["name"]]} application [ {row[PATTERN["apps"]]} ]\n')
            f.write('\n')
            f.write(f'set rulebase security rules {row[PATTERN["name"]]} log-start no\n')
            f.write('\n')
            f.write(f'set rulebase security rules {row[PATTERN["name"]]} log-start yes\n')
            f.write('\n')
            f.write('\n')
    f.write('set rulebase default-security-rules rules intrazone-default action drop\n')
    f.write('\n')
    f.write('set rulebase default-security-rules rules intrazone-default log-end yes\n')
    f.write('\n')
    f.write('set rulebase default-security-rules rules interzone-default action deny\n')
    f.write('\n')
    f.write('set rulebase default-security-rules rules interzone-default log-end yes\n')
    f.write('\n')