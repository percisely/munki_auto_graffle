--This script iterates a directory of Munki manifest files, draws a shape for each file, then connects the shapes according to their included_manifests keys.

--Requirements:
---OmniGraffle Pro
---Tested with version 6

--Known Issues:
---1. Doesn't tolerate space in path to manifests folder

property manifestShape : "NoteShape"
property thePlistBuddy : "/usr/libexec/PlistBuddy"
property manifestFont : "Helvetica"


--Prompt for  Manifests Directory
set manifestsDirectory to (choose folder with prompt "select Munki manifests directory")


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


-- make a list of the manifests
set manifestList to (list folder manifestsDirectory without invisibles)



--loop to create manifest shapes.
repeat with theManifests in manifestList
	set currentManifest to theManifests
	drawShape(manifestShape, currentManifest, currentManifest, manifestFont)
end repeat


--loop to link manifest shapes
--currently using plist buddy to drill into the manifest > the included_manifests key and then the individual list items.  
--Starts from 0, asks for an item and iterates up until an error, which breaks the sub-loop and moves on to the next manifest.  
--Will probably break if a manifest contains a manifest that doesn't exist.  
--Potentially could be made better by using plistlib.readPlist
repeat with theItems in manifestList
	set currentIndex to 0
	set currentContainerManifest to theItems
	set currentManifestPath to POSIX path of manifestsDirectory & currentContainerManifest
	try
		repeat
			--set currentIncludedManifest to do shell script thePlistBuddy & " -c \"print " & ":included_manifests:" & currentIndex & "\" " & currentManifestPath
			set currentIncludedManifest to readKey(currentManifestPath, "included_manifests", currentIndex)
			link(currentIncludedManifest, currentContainerManifest, "straight")
			set currentIndex to currentIndex + 1
		end repeat
	end try
end repeat

--plist buddy function to pull data from a specified array and key by array name and key index.  
on readKey(targetFile, targetArray, targetKeyIndex)
	set keyValue to do shell script "/usr/libexec/PlistBuddy" & " -c \"print " & ":" & targetArray & ":" & targetKeyIndex & "\" " & targetFile
	return keyValue
end readKey

--link function
on link(originShape, targetShape, propLineType)
	tell application "OmniGraffle"
		tell canvas of front window
			connect shape originShape to shape targetShape with properties {thickness:1, stroke color:{0, 0, 0}, head type:"FilledArrow", stroke pattern:0, line type:propLineType}
			layout
		end tell
	end tell
end link


--draw shapes function
on drawShape(shapeProp, textProp, nameProp, fontProp)
	tell application "OmniGraffle"
		tell canvas of front window
			make new shape at end of graphics with properties {name:shapeProp, size:{144.0, 144.0}, text:{alignment:center, font:fontProp, size:"12", text:textProp}, origin:{135.0, 99.0}, user name:nameProp}
		end tell
		layout
	end tell
end drawShape