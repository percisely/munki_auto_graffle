--This script iterates a directory of Munki manifest files, draws a shape for each file, then connects the shapes according to their included_manifests keys.

--Requirements:
---OmniGraffle Pro
---Tested with version 6

--Known Issues:
---1. Doesn't tolerate space in path to manifests folder
---2. Doesn't work with installers nested in conditional_items 
--3. Sinlge File Mode doesn't work yet
--4. Don't seem to be picking up managed_updates

--Color Hints
---Smokey Fern: {0.137255, 0.368627, 0.000000}
---Ocean: {0.000000, 0.215686, 0.462745}
---Cayane: {0.694118, 0.000000, 0.109804}

property defaultLineType : "Straight"

property manifestShape : "NoteShape"
property installShape : "Cube"

property manifestFont : "Helvetica"
property installFont : "Helvetica"


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
	drawShape(manifestShape, currentContainerManifest, currentContainerManifest, manifestFont)
	--get included manifests, draw and link
	try
		repeat
			set currentIncludedManifest to readKey(currentManifestPath, "included_manifests", currentIndex)
			drawShape(manifestShape, currentIncludedManifest, currentIncludedManifest, manifestFont)
			link(currentIncludedManifest, currentContainerManifest, manifestLinkColor, defaultLineType, manifestArrowHeadType, manifestLinkStyle)
			layoutGraffle()
			set currentIndex to currentIndex + 1
		end repeat
		set currentIndex to 0
	end try
	if theDataChoicesList contains "managed_installs" then
		--get managed installs, draw and link
		try
			repeat
				set currentManagedInstall to readKey(currentManifestPath, "managed_installs", currentIndex)
				drawShape(installShape, currentManagedInstall, currentManagedInstall, installFont)
				link(currentManagedInstall, currentContainerManifest, managedInstallLinkColor, defaultLineType, managedInstallArrowHeadType, managedInstallLinkStyle)
				layoutGraffle()
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
				drawShape(installShape, currentOptionalInstall, currentOptionalInstall, installFont)
				link(currentOptionalInstall, currentContainerManifest, optionalInstallLinkColor, defaultLineType, optionalInstallArrowHeadType, optionalInstallLinkStyle)
				layoutGraffle()
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
				drawShape(installShape, currentManagedUpdate, currentManagedUpdate, installFont)
				link(currentManagedUpdate, currentContainerManifest, managedUpdateLinkColor, defaultLineType, managedUpdateArrowHeadType, managedUpdateLinkStyle)
				layoutGraffle()
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
				drawShape(installShape, currentManagedUninstall, currentManagedUninstall, installFont)
				link(currentManagedUninstall, currentContainerManifest, managedUninstallLinkColor, defaultLineType, managedUninstallArrowHeadType, managedUninstallLinkStyle)
				layoutGraffle()
				set currentIndex to currentIndex + 1
			end repeat
			set currentIndex to 0
		end try
	end if
	
end repeat

linesToBack()

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
on drawShape(shapeProp, textProp, nameProp, fontProp)
	tell application "OmniGraffle"
		tell canvas of front window
			try
				set f to first graphic whose tag is nameProp
				return f
			on error
				-- not found - make a new one
				make new shape at end of graphics with properties {name:shapeProp, size:{144.0, 144.0}, text:{alignment:center, draws shadow:false, font:fontProp, size:"12", text:textProp}, origin:{135.0, 99.0}, user name:nameProp, tag:nameProp}
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

