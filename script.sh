#!/bin/bash
#Script to prepare JSON output from release notes step in VSTS releases to be transformed into a dynamic HTML table
#jq required (https://stedolan.github.io/jq)
#Stepped for troubleshooting purposes

#Encode
dos2unix *.json

#Escape quotes - staggered for troubleshooting
##CSS styles
sed -i 's|<span style=\"|<span style=\\\"|g' *.json
#URLs
sed -i 's|<a href=\"|<a href=\\\"|g' *.json
#Closing angle brackets
sed -i 's|\">|\\\">|g' *.json

#Bold to code style
sed -i -E 's|<span style=\\\"font-weight:bold;\\\">([^<]*)</span>|<code>\1</code>|g;' *.json
sed -i -E 's|<b>([^<]*)</b>|<code>\1</code>|g;' *.json
sed -i -E 's|<b>([^<]*)<b/>|<code>\1</code>|g;' *.json

##To address periods in strings
sed -i -E 's|<span style=\\\"font-weight: bold;\\\">([a-zA-Z0-9:& ]*)\.([a-zA-Z0-9:& ]*)|<code>\1\2</code>|g;' *.json

##Removable if not working in CAP VSTS project: Strange corner case in 18.1.18165.03 for 2012 and 2016
sed -i -E 's|<b>Arithmetic|Arithmetic|g;' *.json
sed -i -E 's|int.<b>|<code>int.</code>|g;' *.json

#Removable if not working in CAP VSTS project: Two early releases were called CAP 18.1 - replace with DOS 18.1
sed -i 's|CAP 18|DOS 18|g;' *.json

#JQ does not allow inplace - combines *.json into one
cat *.json > 1.json
jq . -s 1.json > 2.json

#Remove objects where publish does not equal Yes
jq -r 'del(.[] | select(.publish != "Yes"))' <2.json >3.json

#Select which fields to output
jq '.[] |= {releaseDate,"fullName":.releaseName,"sqlServerVersion":.releaseName,"software":.releaseName,releaseName,releaseNote,type,productsAffected,id}' <3.json >4.json 

#Limit "releaseDate" to just the date
jq '[.[] | .releaseDate |= sub(" ........"; "")]' <4.json >5.json 

#Remove triggered by from .fullName
jq '[.[] | ."fullName" |= sub(" triggered on(.*?)......-......";"")]' <5.json >6.json 

#Limit "releaseName" to just the release name
jq '[.[] | .releaseName |= sub(" for SQL 20.."; "") | ."releaseName" |= sub(" triggered on(.*?)......-......";"") | ."releaseName" |= sub("[A-Z](.*?) ";"")]' <6.json >7.json

#Limit "SQL Server version" to just the version
jq '[.[] | .sqlServerVersion |= sub("[A-Z](.*?)for "; "") | .sqlServerVersion |= sub(" triggered on(.*?)......-......";"")]' <7.json >8.json
##Replace SQL Server version for SMD and SAMD with N/A
jq '[.[] | .sqlServerVersion |= sub("S(.*?) ........"; "N/A")]' <8.json >9.json

#Limit "Software" to just the software
##CAP and DOS
jq '[.[] | .software |= sub(" (.*?) for SQL 20.. triggered on(.*?)......-......";"")]' <9.json >10.json
##SAMD AND SMD
jq '[.[] | .software |= sub(" (.*?) triggered on(.*?)......-......";"")]' <10.json >11.json

#Change bug to patched bug and PBI to added functionality
jq 'map(if .type== "Bug" then .type= "Patched bug" else . end) | map(if .type== "Product Backlog Item" then .type= "Added functionality" else . end)' <11.json >12.json

#Split products affected into array
jq 'map(.productsAffected |= split(";"))' <12.json >13.json
