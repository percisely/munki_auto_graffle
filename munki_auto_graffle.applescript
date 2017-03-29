--This script iterates a directory of Munki manifest files, draws a shape for each file, then connects the shapes according to their included_manifests keys.

--Requirements:
---OmniGraffle Pro
---Tested with version 6

--Known Issues:
---1. Doesn't tolerate space in path to manifests folder
---2. Doesn't work with installers nested in conditional_items 
---3. Sinlge File Mode doesn't work yet

--Color Hints
--Black: {0, 0, 0}
--White: {65535, 65533, 65534}
---Smokey Fern: {0.137255, 0.368627, 0.000000}
---Ocean: {0.000000, 0.215686, 0.462745}
---Cayane: {0.694118, 0.000000, 0.109804}
---LEGO Theme
----Yellow: {65535, 65535, 0} --yellow
----Blue: {0, 0, 65535} --blue
----Red: {65535, 0, 0} --red
----Green: {0, 65535, 0} --green

property defaultLineType : "Straight"

property manifestShape : "NoteShape"
property installShape : "Cube"
property computerShape : "Octagon"
property groupShape : "Circle"

property manifestShapeColor : {65535, 65535, 0} --yellow
property installShapeColor : {0, 65535, 0} --green
property computerShapeColor : {65535, 0, 0} --red
property groupShapeColor : {0, 0, 65535} --blue

property manifestFont : "Helvetica"
property installFont : "Helvetica"
property computerFont : "Helvetica"
property groupFont : "Helvetica"

property manifestFontColor : {0, 0, 0}
property installFontColor : {65535, 65533, 65534}
property computerFontColor : {0, 0, 0}
property groupFontColor : {65535, 65533, 65534}


property manifestLinkColor : {0, 0, 0}
property manifestLinkStyle : 0
property manifestArrowHeadType : "FilledArrow"

property managedInstallLinkColor : {0.137255, 0.368627, 0.0}
property managedInstallLinkStyle : 0
property managedInstallArrowHeadType : "FilledDoubleArrow"

property optionalInstallLinkColor : {0.0, 0.215686, 0.462745}
property optionalInstallLinkStyle : 1
property optionalInstallArrowHeadType : ""

property managedUpdateLinkColor : {0.137255, 0.368627, 0.0}
property managedUpdateLinkStyle : 1
property managedUpdateArrowHeadType : "FilledDoubleArrow"

property managedUninstallLinkColor : {0.694118, 0.0, 0.109804}
property managedUninstallLinkStyle : 9
property managedUninstallArrowHeadType : "SharpBackArrow"


--Prompt for folder or single manifest mode
set sourceModeChoice to button returned of (display dialog "Diagram entire manifests directory, or start from a single manifest?" buttons {"Manifests Directory", "Single Manifest"} default button "Manifests Directory")
if sourceModeChoice contains "Manifests Directory" then
	set sourceMode to "directoryMode"
else if sourceModeChoice contains "Single Manifest" then
	set sourceMode to "singleFileMode"
end if

if sourceMode is equal to "directoryMode" then
	--Prompt for  Manifests Directory
	set manifestsDirectory to (choose folder with prompt "Select Munki manifests directory")
	-- make a list of the manifests
	set manifestList to (list folder manifestsDirectory without invisibles)
else if sourceMode is equal to "singleFileMode" then
	set theManifest to (choose file with prompt "Select Munki manifest")
	set theManifestName to name of (info for theManifest)
	set manifestList to {theManifestName}
end if

--Prompt for folder or single manifest mode.  Could add option to try to curl it from https://<vanity>.monitoringclient.com/computers.csv?direction=asc&sort=group
set watchmanModeChoice to button returned of (display dialog "Include computer data from Watchman?  Requires .csv export from Watchman Monitoring." buttons {"Include Computers", "Manifests Only"} default button "Manifests Only")
if watchmanModeChoice contains "Include Computers" then
	set watchmanMode to "true"
	set theWatchmanCSV to (choose file with prompt "Select Watchman Computers CSV")
else if watchmanModeChoice contains "Manifests Only" then
	set watchmanMode to "false"
end if

--Prompt for data source option.
set displayInstallChoice to display dialog "Include Unconditional Installs and Uninstalls?" buttons {"Include Installs", "Manifests Only"} default button "Manifests Only"
set currentInstallChoice to button returned of displayInstallChoice
if currentInstallChoice contains "Include Installs" then
	set theDataChoicesList to {"included_manifests", "managed_installs", "optional_installs", "managed_updates", "managed_uninstalls"}
else if currentInstallChoice contains "Manifests Only" then
	set theDataChoicesList to {"included_manifests"}
end if


--Fire up OmniGraffle and make a new document
---object separation property not working
tell application "OmniGraffle"
	activate
	make new document with properties {template:"Auto-Resizing"}
	set properties of first canvas of first document to {layout info:{automatic layout:true, type:hierarchical, direction:top to bottom, object separation:1.0, rank separation:5}}
end tell


--zoom out
tell application "OmniGraffle"
	set properties of first window to {zoom:0.15}
end tell


--loop to link manifest shapes
---currently using plist buddy to drill into the manifest > the included_manifests key and then the individual list items.  
---Starts from 0, asks for an item and iterates up until an error, which breaks the sub-loop and moves on to the next manifest.  
---Will probably break if a manifest contains a manifest that doesn't exist.  
---Potentially could be made better by using plistlib.readPlist
repeat with i in manifestList
	layoutGraffle()
	set currentIndex to 0
	set currentContainerManifest to i
	if sourceMode is equal to "directoryMode" then
		set currentManifestPath to POSIX path of manifestsDirectory & currentContainerManifest
	else if sourceMode is equal to "singleFileMode" then
		set currentManifestPath to POSIX path of theManifest
	end if
	drawShape(manifestShape, currentContainerManifest, currentContainerManifest, manifestFont, manifestFontColor, manifestShapeColor)
	--get included manifests, draw and link
	try
		repeat
			set currentIncludedManifest to readKey(currentManifestPath, "included_manifests", currentIndex)
			drawShape(manifestShape, currentIncludedManifest, currentIncludedManifest, manifestFont, manifestFontColor, manifestShapeColor)
			link(currentIncludedManifest, currentContainerManifest, manifestLinkColor, defaultLineType, manifestArrowHeadType, manifestLinkStyle)
			--layoutGraffle()
			set currentIndex to currentIndex + 1
		end repeat
		set currentIndex to 0
	end try
	if theDataChoicesList contains "managed_installs" then
		--get managed installs, draw and link
		try
			repeat
				set currentManagedInstall to readKey(currentManifestPath, "managed_installs", currentIndex)
				drawShape(installShape, currentManagedInstall, currentManagedInstall, installFont, installFontColor, installShapeColor)
				link(currentManagedInstall, currentContainerManifest, managedInstallLinkColor, defaultLineType, managedInstallArrowHeadType, managedInstallLinkStyle)
				--layoutGraffle()
				set currentIndex to currentIndex + 1
			end repeat
			set currentIndex to 0
		end try
	end if
	if theDataChoicesList contains "optional_installs" then
		--get optional installs, draw and link
		try
			repeat
				set currentOptionalInstall to readKey(currentManifestPath, "optional_installs", currentIndex)
				drawShape(installShape, currentOptionalInstall, currentOptionalInstall, installFont, installFontColor, installShapeColor)
				link(currentOptionalInstall, currentContainerManifest, optionalInstallLinkColor, defaultLineType, optionalInstallArrowHeadType, optionalInstallLinkStyle)
				--layoutGraffle()
				set currentIndex to currentIndex + 1
			end repeat
			set currentIndex to 0
		end try
	end if
	if theDataChoicesList contains "managed_updates" then
		--get managed updates, draw and link
		try
			repeat
				set currentManagedUpdate to readKey(currentManifestPath, "managed_updates", currentIndex)
				drawShape(installShape, currentManagedUpdate, currentManagedUpdate, installFont, installFontColor, installShapeColor)
				link(currentManagedUpdate, currentContainerManifest, managedUpdateLinkColor, defaultLineType, managedUpdateArrowHeadType, managedUpdateLinkStyle)
				--layoutGraffle()
				set currentIndex to currentIndex + 1
			end repeat
			set currentIndex to 0
		end try
	end if
	if theDataChoicesList contains "managed_uninstalls" then
		--get managed uninstalls, draw and link
		try
			repeat
				set currentManagedUninstall to readKey(currentManifestPath, "managed_uninstalls", currentIndex)
				drawShape(installShape, currentManagedUninstall, currentManagedUninstall, installFont, installFontColor, installShapeColor)
				link(currentManagedUninstall, currentContainerManifest, managedUninstallLinkColor, defaultLineType, managedUninstallArrowHeadType, managedUninstallLinkStyle)
				--layoutGraffle()
				set currentIndex to currentIndex + 1
			end repeat
			set currentIndex to 0
		end try
	end if
	
end repeat

--add computers from Watchman CSV
if watchmanMode is equal to "true" then
	set csvText to read theWatchmanCSV
	set theList to csvToList(csvText, {})
	set theHeaderList to item 1 of theList
	set theListWithoutHeaders to items 2 thru -1 of theList
	set theMunkiIndex to indexof("Munki Identifier", theHeaderList)
	set theWatchmanIDIndex to indexof("Watchman ID", theHeaderList)
	set theGroupIndex to indexof("Group", theHeaderList)
	set theComputerNameIndex to indexof("Computer Name", theHeaderList)
	set theSerialIndex to indexof("Serial Number", theHeaderList)
	set currentComputerAsList to {}
	repeat with i in theListWithoutHeaders
		set currentComputerAsList to i
		set currentComputerID to item theWatchmanIDIndex of currentComputerAsList
		set currentComputerGroup to item theGroupIndex of currentComputerAsList
		set currentComputerName to item theComputerNameIndex of currentComputerAsList
		set currentComputerSerial to item theSerialIndex of currentComputerAsList
		set currentComputerMunkiManifest to item theMunkiIndex of currentComputerAsList
		if currentComputerMunkiManifest is not equal to "" then
			if currentComputerMunkiManifest is not equal to "n/a" then
				--drawShape(shapeProp, textProp, nameProp, fontProp)
				drawShape(computerShape, currentComputerName, currentComputerID, computerFont, computerFontColor, computerShapeColor)
				drawShape(groupShape, currentComputerGroup, currentComputerGroup, groupFont, groupFontColor, groupShapeColor)
				drawShape(manifestShape, currentComputerMunkiManifest, currentComputerMunkiManifest, manifestFont, manifestFontColor, manifestShapeColor)
				--link(originShape, targetShape, propLineColor, propLineType, propHeadType, propStrokePattern)
				link(currentComputerName, currentComputerGroup, manifestLinkColor, defaultLineType, manifestArrowHeadType, manifestLinkStyle)
				link(currentComputerMunkiManifest, currentComputerName, manifestLinkColor, defaultLineType, manifestArrowHeadType, manifestLinkStyle)
			end if
		end if
	end repeat
end if



linesToBack()
layoutGraffle()

--return theManifest & " " & POSIX path of theManifest & " " & manifestList
end

--plist buddy function to pull data from a specified array and key by array name and key index.  
on readKey(targetFile, targetArray, targetKeyIndex)
	set keyValue to do shell script "/usr/libexec/PlistBuddy" & " -c \"print " & ":" & targetArray & ":" & targetKeyIndex & "\" " & targetFile
	return keyValue
end readKey

--link function
on link(originShape, targetShape, propLineColor, propLineType, propHeadType, propStrokePattern)
	tell application "OmniGraffle"
		tell canvas of front window
			connect shape originShape to shape targetShape with properties {thickness:1, stroke color:propLineColor, draws shadow:false, head type:propHeadType, stroke pattern:propStrokePattern, line type:propLineType}
			layout
		end tell
	end tell
end link


--draw shape function
---won't draw shapes with duplicate tags, and tag is set to name.
on drawShape(shapeProp, textProp, nameProp, fontProp, fontColorProp, shapeColorProp)
	tell application "OmniGraffle"
		tell canvas of front window
			try
				set f to first graphic whose tag is nameProp
				return f
			on error
				-- not found - make a new one
				make new shape at end of graphics with properties {name:shapeProp, size:{144.0, 144.0}, text:{alignment:center, draws shadow:false, font:fontProp, size:"12", color:fontColorProp, text:textProp}, origin:{135.0, 99.0}, fill color:shapeColorProp, user name:nameProp, tag:nameProp}
			end try
		end tell
		layout
	end tell
end drawShape

--layout function, so I can add it without cluttering code
on layoutGraffle()
	tell application "OmniGraffle"
		tell canvas of front window
			layout
		end tell
	end tell
end layoutGraffle

--lines to back layer function
on linesToBack()
	tell application "OmniGraffle"
		tell canvas of front window
			set lineLayer to make new layer at end of layers with properties {name:"Lines", visible:true}
			set layer of every line to lineLayer
		end tell
	end tell
end linesToBack

--csv to list function
---from http://macscripter.net/viewtopic.php?pid=125444#p125444
(* Assumes that the CSV text adheres to the convention:
   Records are delimited by LFs or CRLFs (but CRs are also allowed here).
   The last record in the text may or may not be followed by an LF or CRLF (or CR).
   Fields in the same record are separated by commas (unless specified differently by parameter).
   The last field in a record must not be followed by a comma.
   Trailing or leading spaces in unquoted fields are not ignored (unless so specified by parameter).
   Fields containing quoted text are quoted in their entirety, any space outside them being ignored.
   Fields enclosed in double-quotes are to be taken verbatim, except for any included double-quote pairs, which are to be translated as double-quote characters.
       
   No other variations are currently supported. *)

on csvToList(csvText, implementation)
	-- The 'implementation' parameter must be a record. Leave it empty ({}) for the default assumptions: ie. comma separator, leading and trailing spaces in unquoted fields not to be trimmed. Otherwise it can have a 'separator' property with a text value (eg. {separator:tab}) and/or a 'trimming' property with a boolean value ({trimming:true}).
	set {separator:separator, trimming:trimming} to (implementation & {separator:",", trimming:false})
	
	script o -- Lists for fast access.
		property qdti : getTextItems(csvText, "\"")
		property currentRecord : {}
		property possibleFields : missing value
		property recordList : {}
	end script
	
	-- o's qdti is a list of the CSV's text items, as delimited by double-quotes.
	-- Assuming the convention mentioned above, the number of items is always odd.
	-- Even-numbered items (if any) are quoted field values and don't need parsing.
	-- Odd-numbered items are everything else. Empty strings in odd-numbered slots
	-- (except at the beginning and end) indicate escaped quotes in quoted fields.
	
	set astid to AppleScript's text item delimiters
	set qdtiCount to (count o's qdti)
	set quoteInProgress to false
	considering case
		repeat with i from 1 to qdtiCount by 2 -- Parse odd-numbered items only.
			set thisBit to item i of o's qdti
			if ((count thisBit) > 0) or (i is qdtiCount) then
				-- This is either a non-empty string or the last item in the list, so it doesn't
				-- represent a quoted quote. Check if we've just been dealing with any.
				if (quoteInProgress) then
					-- All the parts of a quoted field containing quoted quotes have now been
					-- passed over. Coerce them together using a quote delimiter.
					set AppleScript's text item delimiters to "\""
					set thisField to (items a thru (i - 1) of o's qdti) as string
					-- Replace the reconstituted quoted quotes with literal quotes.
					set AppleScript's text item delimiters to "\"\""
					set thisField to thisField's text items
					set AppleScript's text item delimiters to "\""
					-- Store the field in the "current record" list and cancel the "quote in progress" flag.
					set end of o's currentRecord to thisField as string
					set quoteInProgress to false
				else if (i > 1) then
					-- The preceding, even-numbered item is a complete quoted field. Store it.
					set end of o's currentRecord to item (i - 1) of o's qdti
				end if
				
				-- Now parse this item's field-separator-delimited text items, which are either non-quoted fields or stumps from the removal of quoted fields. Any that contain line breaks must be further split to end one record and start another. These could include multiple single-field records without field separators.
				set o's possibleFields to getTextItems(thisBit, separator)
				set possibleFieldCount to (count o's possibleFields)
				repeat with j from 1 to possibleFieldCount
					set thisField to item j of o's possibleFields
					if ((count thisField each paragraph) > 1) then
						-- This "field" contains one or more line endings. Split it at those points.
						set theseFields to thisField's paragraphs
						-- With each of these end-of-record fields except the last, complete the field list for the current record and initialise another. Omit the first "field" if it's just the stub from a preceding quoted field.
						repeat with k from 1 to (count theseFields) - 1
							set thisField to item k of theseFields
							if ((k > 1) or (j > 1) or (i is 1) or ((count trim(thisField, true)) > 0)) then set end of o's currentRecord to trim(thisField, trimming)
							set end of o's recordList to o's currentRecord
							set o's currentRecord to {}
						end repeat
						-- With the last end-of-record "field", just complete the current field list if the field's not the stub from a following quoted field.
						set thisField to end of theseFields
						if ((j < possibleFieldCount) or ((count thisField) > 0)) then set end of o's currentRecord to trim(thisField, trimming)
					else
						-- This is a "field" not containing a line break. Insert it into the current field list if it's not just a stub from a preceding or following quoted field.
						if (((j > 1) and ((j < possibleFieldCount) or (i is qdtiCount))) or ((j is 1) and (i is 1)) or ((count trim(thisField, true)) > 0)) then set end of o's currentRecord to trim(thisField, trimming)
					end if
				end repeat
				
				-- Otherwise, this item IS an empty text representing a quoted quote.
			else if (quoteInProgress) then
				-- It's another quote in a field already identified as having one. Do nothing for now.
			else if (i > 1) then
				-- It's the first quoted quote in a quoted field. Note the index of the
				-- preceding even-numbered item (the first part of the field) and flag "quote in
				-- progress" so that the repeat idles past the remaining part(s) of the field.
				set a to i - 1
				set quoteInProgress to true
			end if
		end repeat
	end considering
	
	-- At the end of the repeat, store any remaining "current record".
	if (o's currentRecord is not {}) then set end of o's recordList to o's currentRecord
	set AppleScript's text item delimiters to astid
	
	return o's recordList
end csvToList

-- Get the possibly more than 4000 text items from a text.
on getTextItems(txt, delim)
	set astid to AppleScript's text item delimiters
	set AppleScript's text item delimiters to delim
	set tiCount to (count txt's text items)
	set textItems to {}
	repeat with i from 1 to tiCount by 4000
		set j to i + 3999
		if (j > tiCount) then set j to tiCount
		set textItems to textItems & text items i thru j of txt
	end repeat
	set AppleScript's text item delimiters to astid
	
	return textItems
end getTextItems

-- Trim any leading or trailing spaces from a string.
on trim(txt, trimming)
	if (trimming) then
		repeat with i from 1 to (count txt) - 1
			if (txt begins with space) then
				set txt to text 2 thru -1 of txt
			else
				exit repeat
			end if
		end repeat
		repeat with i from 1 to (count txt) - 1
			if (txt ends with space) then
				set txt to text 1 thru -2 of txt
			else
				exit repeat
			end if
		end repeat
		if (txt is space) then set txt to ""
	end if
	
	return txt
end trim

#set csvText to "caiv2,2010BBDGRC,\"President, Board of Directors\"" & linefeed & "Another line, for demo purposes"
#csvToList(csvText, {})
--> {{"caiv2", "2010BBDGRC", "President, Board of Directors"}, {"Another line", "for demo purposes"}}


-- function to find index of item in a list from http://macscripter.net/viewtopic.php?pid=130181#p130181
on indexof(theItem, theList) -- credits Emmanuel Levy
	set oTIDs to AppleScript's text item delimiters
	set AppleScript's text item delimiters to return
	set theList to return & theList & return
	set AppleScript's text item delimiters to oTIDs
	try
		-1 + (count (paragraphs of (text 1 thru (offset of (return & theItem & return) in theList) of theList)))
	on error
		0
	end try
end indexof
