
'BlitzMax program : 11 Jan 2014 11:08:33
'Template         : template_2.bmx

Rem
	17/02/2015	1.01			Added options
									RECURSIVE	-	Check for subfolders if set to YES
									FTYPE			-	Look for specific file types
									PREFIX		-	Add a prefix to the filename
									SUFFIX		-	Add a suffix to the filename 
	12/05/2015	1.01.004		Added LIMIT=
	22/10/2015	1.01.005		Make compatable with move_files to replace it
									Add suffix=, emptydir=, sortopt=, destlimit=, replace=
	10/03/2016	1.01.006		Fix mask issue
											Add log_days2keep
											
	18/11/2016	1.01.007	Do not skip when errors encountered. Report any found and move to next entry in list.
	
	05/08/2024 1.02			Add date sub-folder option
	
End Rem

SuperStrict
Include "..\..\public\bmx_extensions.bmx"
Include "..\..\public\bmx_t_logFile.bmx"

AppTitle = "Filewatcher"
Const progname:String = "FileWatcher"
Const version:String = "1.02"
Const moddate:String = "03/08/2024"
Const builddate:String = "03/08/2024"
Global runmode:Int = 0
Global exclude_list:String[]
Global report_excludes:Int=True
Global limit:Int = 0
Global log_days2keep:Int = 30

Const test_mode:Int = 0;
Const copy_mode:Int = 1;
Const move_mode:Int = 2;


t_logFile.Set_LogPath("logs\FileWatcher")
t_logFile.DisplayON()
t_logFile.WriteLog("Started")
t_logFile.WriteLog("Version "+version+" "+builddate)
Local pathlist:String[]
Local infile:TStream = ReadFile("FileWatcher.ini")
If infile = Null
	t_logFile.WriteLog("***ERROR*** Unable to load .ini file, aborting")
	End
Else
	While Not Eof(infile)
		Local linedata:String = Upper(ReadLine(infile))
		If Instr(linedata,"RUNMODE=")=1
			runmode=Int(getstring(linedata,"RUNMODE=",";"))	
		End If
		If Instr(linedata,"LIMIT=")=1
			limit = Int(getstring(linedata,"LIMIT=",";"))
			If limit<0 Then limit = 0
		End If
		If Instr(linedata,"EXCLUDE=")=1
				Local count:Int = Len(exclude_list)
				exclude_list = exclude_list[..count+1]
				exclude_list[count] = getstring(linedata,"EXCLUDE=",";")
		End If
		If Instr(linedata,"REPORT_EXCLUDES=")=1
			If getstring(linedata,"=",";")="NO"
				report_excludes=False
			End If
		End If
		If Instr(linedata,"PATH=")=1
			''Print linedata	
			Local count:Int = Len(pathlist)
			pathlist = pathlist[..count+1]
			pathlist[count] = linedata
		End If
		If strfind(linedata, "log_days2keep=") > 0
			Local temp:Int = Int(getString(linedata,"LOG_DAYS2KEEP=",";",True))
			If temp>0
				log_days2keep = temp
			Else
				log_days2keep = Null
			End If
		EndIf
	Wend
	If log_days2keep>0
		t_logfile.set_days2keep(log_days2keep)
	End If
	
	CloseFile infile
End If

If Len(pathlist)=0
	t_logFile.WriteLog("Pathlist is empty. Process stopping")
Else
	Select runmode
		Case copy_mode
			t_logFile.WriteLog(" COPY MODE ")
		Case move_mode
			t_logFile.WriteLog(" MOVE MODE ")
		Default
			t_logFile.WriteLog(" TEST MODE ")
	End Select
	t_logFile.WriteLog("Source Limit "+limit)
	If log_days2keep>0
		t_logFile.WriteLog("Log file Retention "+log_days2keep)
	EndIf
	For Local text:String = EachIn pathlist
		'Print text
		Local source:String 	= getstring(text,"PATH=",";")
		Local mask:String 		= getstring(text,"MASK=",";")
		Local dest:String 		= getstring(text,"DEST=",";")
		Local recursive:Int 	= Int(getstring(text,"RECURSIVE=",";"))
		Local ftype:String 		= getstring(text,"FTYPE=",";")
		Local prefix:String 	= getstring(text,"PREFIX=",";")
		Local suffix:String 	= getstring(text,"SUFFIX=",";")
		Local destlimit:Int		= Int(getstring(text,"DESTLIMIT=",";"))
		Local emptydir:Int		= Int(getstring(text,"EMPTYDIR=",";"))
		Local sortopt:Int			= Int(getstring(text,"SORTOPT=",";"))
		Local replaceFile:Int	= Int(getstring(text,"REPLACE=",";"))
		Local flag_mkdir:Int = Int(getstring(text, "MKDIR=", ";"))
		Local flag_datefolder:Int = Int(getstring(text, "datefolder=", ";"))
		Local errors:Int = False
				
'		If Len(exclude_list)>0
'			For Local text:String = EachIn exclude_list
'				t_logFile.WriteLog("exclude = "+text)
'			Next
'		End If
		If source = ""
			t_logFile.WriteLog("*** source is blank. Process skipped. ***")
			errors = True
		Else
			If FileType(source)<>2
				t_logFile.WriteLog("*** "+source+" not found. Process skipped. ***")
				errors = True
			End If
		End If
		If mask = ""
			t_logFile.WriteLog("*** mask is blank. Process skipped. ***")
			errors = True
		End If
		If dest = ""
			t_logFile.WriteLog("*** dest is blank. Process skipped. ***")
			errors = True
		Else
			If FileType(dest)<>2
				t_logFile.WriteLog("*** "+dest+" not found. Process skipped. ***")
				errors = True
			End If
		End If
		If errors = False 
			get_files(source, mask, dest, recursive, ftype, prefix, suffix, replaceFile, flag_mkdir, flag_datefolder)
		End If
	Next
End If

t_logFile.WriteLog("Completed")
t_logFIle.Close_LogFile()
End

End
Function get_files(sourcepath:String, mask:String, destpath:String, recursive:Int, ftype:String, prefix:String, suffix:String, replaceFile:Int, flag_mkdir:Int, flag_datefolder:Int) '=Null)
	t_logFile.WriteLog("===============================================================")
	t_logFile.WriteLog("source = "+sourcepath)
'	t_logFile.WriteLog("mask = "+mask)
	t_logFile.WriteLog("dest = "+destpath)
'	t_logFile.WriteLog("recursive = "+recursive)
	t_logfile.WriteLog("ftype= "+ftype)
	t_logfile.WriteLog("prefix= "+prefix)
	t_logfile.WriteLog("suffix= "+suffix)
	't_logfile.WriteLog("destlimit= "+destlimit)
	't_logfile.WriteLog("emptydir= "+emptydir)
	't_logfile.WriteLog("sortopt= "+sortopt)
	t_logfile.WriteLog("replace= "+replaceFile)
	t_logfile.WriteLog("mkdir= " + flag_mkdir)
	t_logfile.WriteLog("datefolder= " + flag_datefolder)

	''Print "get_files("+path+","+mask+","+destpath+")"

	' If Instr(path,"2013")>0 Then Return
	If FileType(sourcepath)<>2 Then Return	
	If mask  = "" Then Return

	Local infilepath:String
	Local outfilepath:String
	Local rc:Int
	Local found:Int = False
	Local filecount:Int 
	
	t_logFile.WriteLog("searching "+sourcepath)
	Local files:String[] = LoadDir(sourcepath)
	''Print Len(files)
	If Len(files)=0
		t_logFile.WriteLog("  Empty directory")
	Else
		filecount = 0
		For Local file:String = EachIn files
			If check_excludes(file)=True
				If report_excludes = True Then t_logFile.WriteLog(" "+file+"  ** excluded from move")
			Else
				infilepath = sourcepath+"\"+file
				'Print file
				'found = False
				Select FileType(infilepath)
					Case 1
						If (mask = "*" Or Instr(file,mask)>0) And (Upper(ExtractExt(file)) = ftype Or ftype = "*")
							If limit<>0 And filecount = limit
								Exit
							End If
							filecount:+1
							outfilepath = destpath + "\"
							If flag_datefolder = True
								outfilepath:+GetFileDate(infilepath, "YYYY-MM-DD") + "\"
								'outfilepath:+GetCurrentDate("YYYY-MM-DD") + "\"
								If FileType(outfilepath) = 0
									CreateDir(outfilepath)
								End If
							End If
							If Trim(prefix)=""
								outfilepath:+file
							Else
								outfilepath:+prefix+file
							End If
							If Trim(suffix) <> ""
								outfilepath:+suffix
							End If
							'Print outfilepath
							Select runmode
								Case copy_mode
									t_logFile.WriteLog(" Copying "+file+" to "+outfilepath)
									If FileType(outfilepath)<>0 
										t_logFile.WriteLog(" file with the same name aleady exists, file skipped")
									Else
										rc = CopyFile(infilepath,outfilepath)
										If rc<> 1
											t_logFile.WriteLog("  ERROR during copy")
										End If
									EndIf
								Case move_mode
									t_logFile.WriteLog(" Moving "+infilepath+" to "+outfilepath)
									If FileType(outfilepath)<>0
										t_logFile.WriteLog(" file with the same name aleady exists, file skipped")
									Else
										rc = RenameFile(infilepath,outfilepath)
										If rc<> 1
											t_logFile.WriteLog("  ERROR during move")
										End If
									EndIf
								Default
									t_logFile.WriteLog( infilepath+" => "+outfilepath)
							End Select
						EndIf
					Case 2
						If recursive = True
							get_files(infilepath, mask, destpath, recursive, ftype, prefix, suffix, replaceFile, flag_mkdir, flag_datefolder)
						End If
				End Select
			End If
		Next
	EndIf
End Function

Function check_excludes:Int(filename:String)
	Local result:Int = False	
	For Local name:String = EachIn exclude_list
		If Instr(Upper(filename),Upper(name))>0
			result=True
			Exit
		End If
	Next
	Return result
End Function

