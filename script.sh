#!/bin/bash
#Script to prepare JSON output from release notes step in VSTS releases to be transformed into a dynamic HTML table
#jq required (https://stedolan.github.io/jq)
#Stepped for troubleshooting purposes

#Create `json` directory at root: `mkdir json-source`
#Add and maintain source files in `json-source`
#Final output file is `test.json` at root
#Copy/paste contents of test.json into Azure > `release-notes` web app > App Service Editor > `test.json`

#Remove `test.json` (final output file) (if it already exists)
rm test.json

#Make JSON processing directory
mkdir json-processing

#Move source files to `json-processing` directory
cp -a json-source/. json-processing/

#Move to `json-processing` directory`
cd json-processing

#Encode all JSON files
dos2unix *.json

#Escape quotes (including hrefs within values)
sed -i -E 's/"/\\&/4g; s/\\"(,)?$/"\1/' *.json

#Remove tabs
sed -i -E 's|\t||g;' *.json

#Bold to code style
##Strange corner case in 18.1.18165.03 for 2012 and 2016 (line is removable if not working in CAP VSTS project)
sed -i -E 's|int.<b>|int.</b>|g;' *.json
#Bold to code style
sed -i -E 's|<span style=\\\"font-weight:bold;\\\">([^<]*)</span>|<code>\1</code>|g;' *.json
sed -i -E 's|<b>([^<]*)</b>|<code>\1</code>|g;' *.json
sed -i -E 's|<b>([^<]*)<b/>|<code>\1</code>|g;' *.json
##To address periods in strings
sed -i -E 's|<span style=\\\"font-weight: bold;\\\">([a-zA-Z0-9:& ]*)\.([a-zA-Z0-9:& ]*)|<code>\1\2</code>|g;' *.json

#Two early releases were called CAP 18.1 - replace with DOS 18.1 (line is removable if not working in CAP VSTS project)
sed -i 's|CAP 18|DOS 18|g;' *.json

#JQ does not allow inplace - combines *.json into one
cat *.json > 1.json
jq . -s 1.json > 2.json

#Remove objects where publish does not equal Yes
jq -r 'del(.[] | select(.publish != "Yes"))' <2.json >3.json

#Select which fields to output
jq '.[] |= {releaseDate,buildDate,"fullName":.releaseName,"sqlServerVersion":.releaseName,"software":.releaseName,releaseName,releaseNote,type,versionsAffected,productsAffected,id}' <3.json >4.json

#Limit "buildDate" to just the date
jq '[.[] | .buildDate |= sub(" ........"; "")]' <4.json >5.json 

#Remove triggered by from .fullName
jq '[.[] | ."fullName" |= sub(" triggered on(.*?)......-......";"")]' <5.json >6.json 

#Limit "releaseName" to just the release name
jq '[.[] | .releaseName |= sub(" for SQL 20.."; "") | ."releaseName" |= sub(" triggered on(.*?)......-......";"") | ."releaseName" |= sub("[A-Z](.*?) ";"")]' <6.json >7.json

#Limit "SQL Server version" to just the version
jq '[.[] | .sqlServerVersion |= sub("[A-Z](.*?)for "; "") | .sqlServerVersion |= sub(" triggered on(.*?)......-......";"")]' <7.json >8.json
##Replace SQL Server version for SMD and SAMD with N/A
jq '[.[] | .sqlServerVersion |= sub("S(.*?) ........"; "N/A")]' <8.json >9.json
#N/A carries over numeral (e.g., N/A6)...?
sed -e 's|N/A[0-9]|N/A|g;' <9.json >10.json

#Limit "Software" to just the software
##CAP and DOS
jq '[.[] | .software |= sub(" (.*?) for SQL 20.. triggered on(.*?)......-......";"")]' <10.json >11.json
##SAMD AND SMD
jq '[.[] | .software |= sub(" (.*?) triggered on(.*?)......-......";"")]' <11.json >12.json

#New column to abbreviate "Software"
##Duplicate fullName field, combine full name and release date
jq '.[] |= {id,type,productsAffected,versionsAffected,buildDate,releaseDate,fullName: (.fullName + " released " + .releaseDate),sqlServerVersion,software,"softwareAbbrev":.fullName,releaseName,releaseNote}' <12.json >13.json
##Remove SQL Server version for CAP and DOS
jq '[.[] | .softwareAbbrev |= sub(" for SQL 20.."; "")]' <13.json >14.json
jq '[.[] | .softwareAbbrev |= match("[A-Z]* [0-9]*[0-9].[0-9]").string]' <14.json >15.json

#Change bug to patched bug and PBI to added functionality
jq 'map(if .type== "Bug" then .type= "Patched bug" else . end) | map(if .type== "Product Backlog Item" then .type= "Added functionality" else . end)' <15.json >16.json

#Split versions affected into array
jq 'map(.versionsAffected |= split(";"))' <16.json >17.json

#Split products affected into array
jq 'map(.productsAffected |= split(";"))' <17.json >test.json

#Move to root directory
cd ..

#copy `test.json` to root directory
cp json-processing/test.json .

#Remove `json-processing` directory
rm -rf json-processing