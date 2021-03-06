package basisapple;

import basis.settings.ISettings;
import basis.settings.Target;
import basis.FileUtil;
import basis.ProcessUtil;
import basisapple.settings.XmlAppleSettings;
import basisapple.settings.AppleTarget;
import basisapple.XCodeProject;
import sys.FileSystem;
import sys.io.File;
import sys.io.FileOutput;


class AppleBuildTool extends basis.BuildTool
{
	static inline public var SIMULATOR_LOCATION:String = "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Applications/iPhone Simulator.app/Contents/MacOS/iPhone Simulator";


	override private function createSettings(path:String):ISettings
	{
		return new XmlAppleSettings(path);
	}
	
	override private function compileTarget(target:Target):Void
	{
		if(target.subTargets.length == 0)
		{
			buildTarget(target);
		}
		else
		{
			for(subTarget in target.subTargets)
				compileTarget(subTarget);
		}
	}
	
	private function buildTarget(target:Target):Void
	{
		var subTarget:AppleTarget = cast(target, AppleTarget);
	
		try
		{
			var libPath:String = FileUtil.getHaxelib("BasisApple");
			
			var deviceTarget:AppleTarget = cast(subTarget, AppleTarget);
		
			var haxeArgs:Array<String> = deviceTarget.getCollection(Target.HAXE_ARGS, true);
			var sourcePaths:Array<String> = deviceTarget.getCollection(Target.SOURCE_PATHS, true);
			var frameworks:Array<String> = deviceTarget.getCollection(AppleTarget.FRAMEWORKS, true);
			var assetPaths:Array<String> = deviceTarget.getCollection(Target.ASSET_PATHS, true);
			var haxeLibs:Array<String> = deviceTarget.getCollection(Target.HAXE_LIBS, true);
			
			
			var deviceType:String = deviceTarget.getSetting(AppleTarget.DEVICE_TYPE);
			var mainClass:String = deviceTarget.getSetting(Target.MAIN);
			if(mainClass == "" || mainClass == null)
				throw("No main class for: " + deviceType);
			
			
			var appName:String = deviceTarget.getSetting(Target.APP_NAME);
		
			var targetPath:String = deviceTarget.getSetting(Target.BUILD_DIR) + "/" + deviceType;
			FileUtil.createDirectory(targetPath);
			
			var haxeBuildPath:String = targetPath + "/haxe/";
			
			FileUtil.createDirectory(haxeBuildPath + "/cpp/src");
			
			var xcodeFiles:String = targetPath + "/Files/";
			var xcodeAssets:String = xcodeFiles + "/assets";
			var xcodeBin:String = xcodeFiles + "/bin/";
			

			FileUtil.createDirectory(xcodeBin);
			FileUtil.createDirectory(xcodeAssets);
				
			
			//------ Create haxe build file ------
			var buildFile:FileOutput = File.write(targetPath + "/build.hxml");
			buildFile.writeString("-cp haxe\n");
			buildFile.writeString("-cpp haxe/cpp\n");
			buildFile.writeString("-D " + deviceTarget.getDeviceTypeCompilerArgument() + "\n");
			if(deviceType == "ios")
				buildFile.writeString("-D ios\n");
			else
				buildFile.writeString("-D macos\n");
				
			buildFile.writeString("-lib BasisApple\n");
			for(arg in haxeArgs)
				buildFile.writeString(arg + "\n");
				
			for(haxelib in haxeLibs)
				buildFile.writeString("-lib " + haxelib + "\n");
			
			buildFile.writeString("-main RealMain\n");
			buildFile.close();
			//------------------------------------
			
			
			//-------- Add source paths ----------
			var mainFound:Bool = false;
			for(a in 0...sourcePaths.length)
			{
				if(FileSystem.exists(sourcePaths[a] + "/" + StringTools.replace(mainClass, ".", "/") + ".hx") )
					mainFound = true;
			
				if(FileSystem.exists(sourcePaths[a]))
				{
					var contents:Array<String> = FileSystem.readDirectory(sourcePaths[a]);
					for(b in 0...contents.length)
					{
						if(contents[b].charAt(0) != ".")
						{
							if(FileSystem.isDirectory(sourcePaths[a] + "/" + contents[b]))
								FileUtil.copyInto(sourcePaths[a] + "/" + contents[b], haxeBuildPath + contents[b]);
							else
								File.copy(sourcePaths[a] + "/" + contents[b], haxeBuildPath + contents[b]);
						}
					}
				}
				else
				{
					throw("Error: source directory not found: " + sourcePaths[a]);
				}
			}
			
			if(!mainFound)
				throw("Error: main file not found: " + mainClass);
			//------------------------------------
			
			
			//-------- Add asset paths -----------
			for(a in 0...assetPaths.length)
			{
				if(FileSystem.exists(assetPaths[a]))
				{
					var contents:Array<String> = FileSystem.readDirectory(assetPaths[a]);
					for(b in 0...contents.length)
					{
						if(contents[b].charAt(0) != ".")
						{
							if(FileSystem.isDirectory(assetPaths[a] + "/" + contents[b]))
								FileUtil.copyInto(assetPaths[a] + "/" + contents[b], xcodeAssets + "/" + contents[b]);
							else
								File.copy(assetPaths[a] + "/" + contents[b], xcodeAssets + "/" + contents[b]);
						}
					}
				}
				else
				{
					throw("Error: asset directory not found: " + assetPaths[a]);
				}
			}
			//------------------------------------
			
			//-------- Main haxe class -----------
			var realMainContent:String = File.getContent(libPath + "template/RealMain.hx");
			realMainContent = StringTools.replace(realMainContent, "MAIN_INCLUDE", mainClass);
			var fout = neko.io.File.write(targetPath + "/haxe/RealMain.hx");
			fout.writeString(realMainContent);
			fout.close();
			//------------------------------------
			
			//------------ Build cpp -------------
			ProcessUtil.runCommand(targetPath, "haxe", ["build.hxml"]);
			FileUtil.createDirectory(xcodeBin + "/hxcpp/");
			//------------------------------------
			
			//----------- Build Start ------------
			File.copy(libPath + "template/BuildBasisStart.xml" , targetPath + "/haxe/cpp/BuildBasisStart.xml");
			var basisStartContent:String = File.getContent(libPath + "template/BasisStart.cpp");
			basisStartContent = StringTools.replace(basisStartContent, "MAIN_INCLUDE", StringTools.replace(mainClass, ".", "/") );
			basisStartContent = StringTools.replace(basisStartContent, "MAIN_CLASS", StringTools.replace(mainClass, ".", "::"));
			fout = neko.io.File.write(targetPath + "/haxe/cpp/src/BasisStart.cpp");
			fout.writeString(basisStartContent);
			fout.close();
			
			ProcessUtil.runCommand(targetPath + "/haxe/cpp", "haxelib", ["run", "hxcpp", "BuildBasisStart.xml", "-D"+ deviceTarget.getDeviceTypeCompilerArgument()]);
			//------------------------------------
			
			
			//------------ Copy Libs -------------
			if(deviceType == "ios")
			{
				if(deviceTarget.getSetting(AppleTarget.SIMULATOR) == "true")
				{
					FileUtil.copyInto(haxeBuildPath + "cpp/obj/iphonesim/src/", xcodeBin);
					
					File.copy(libPath + "/bin/iPhone/libbasisapple.iphonesim.a" , xcodeBin + "/libbasisapple.iphonesim.a");
				
					File.copy(FileUtil.getHaxelib("hxcpp") + "bin/iPhone/libregexp.iphonesim.a" , xcodeBin + "/hxcpp/libregexp.iphonesim.a");
					File.copy(FileUtil.getHaxelib("hxcpp") + "bin/iPhone/libstd.iphonesim.a" , xcodeBin + "/hxcpp/libstd.iphonesim.a");
					File.copy(FileUtil.getHaxelib("hxcpp") + "bin/iPhone/libzlib.iphonesim.a" , xcodeBin + "/hxcpp/libzlib.iphonesim.a");
				}
				else
				{
					File.copy(libPath + "bin/iPhone/libbasisapple.iphoneos-v7.a" , xcodeBin + "/libbasisapple.iphoneos-v7.a");
					File.copy(libPath + "bin/iPhone/libbasisapple.iphoneos.a" , xcodeBin + "/libbasisapple.iphoneos.a");
					
					File.copy(FileUtil.getHaxelib("hxcpp") + "bin/iPhone/libregexp.iphoneos.a" , xcodeBin + "/hxcpp/libregexp.iphoneos.a");
					File.copy(FileUtil.getHaxelib("hxcpp") + "bin/iPhone/libstd.iphoneos.a" , xcodeBin + "/hxcpp/libstd.iphoneos.a");
					File.copy(FileUtil.getHaxelib("hxcpp") + "bin/iPhone/libzlib.iphoneos.a" , xcodeBin + "/hxcpp/libzlib.iphoneos.a");
					File.copy(FileUtil.getHaxelib("hxcpp") + "bin/iPhone/libregexp.iphoneos-v7.a" , xcodeBin + "/hxcpp/libregexp.iphoneos-v7.a");
					File.copy(FileUtil.getHaxelib("hxcpp") + "bin/iPhone/libstd.iphoneos-v7.a" , xcodeBin + "/hxcpp/libstd.iphoneos-v7.a");
					File.copy(FileUtil.getHaxelib("hxcpp") + "bin/iPhone/libzlib.iphoneos-v7.a" , xcodeBin + "/hxcpp/libzlib.iphoneos-v7.a");
				}
				
			}
			else if(deviceTarget.getSetting(Target.TYPE) == "mac")
			{
				FileUtil.copyInto(FileUtil.getHaxelib("hxcpp") + "bin/Mac/", xcodeBin + "/hxcpp/");
				FileUtil.copyInto(libPath + "ndll/Mac/", xcodeBin + "/hxcpp/");
			}
			//------------------------------------
			
			//---- Copy xcode project files ------
			FileUtil.createDirectory(xcodeFiles);
			File.copy(libPath + "template/Main.mm", xcodeFiles + "/Main.mm");
			File.copy(libPath + "template/Info.plist" , xcodeFiles + appName + "-Info.plist");
			File.copy(libPath + "template/prefix.pch" , xcodeFiles + "/prefix.pch");
			//------------------------------------
			
			
			//-------- Create XCode Project -------
			var xcode:XCodeProject = new XCodeProject(appName);
			xcode.addSouce("Main.mm");
			
			xcode.addSourceDirectory("bin", xcodeBin);
			xcode.addSourceDirectory("assets", xcodeAssets, true);
			xcode.addPlist(appName + "-Info.plist");
			
			for(b in 0...frameworks.length)
				xcode.addFramework(frameworks[b]);
				
			xcode.save(targetPath);
			//------------------------------------
			
			
			//-------- Build Xcode Project -------
			var configuration:String = "Debug";
			var commands = [ "-configuration", configuration ];
			
			if (deviceTarget.getSetting(AppleTarget.SIMULATOR) == "true")
			{
				
	            commands.push ("-arch");
	            commands.push ("i386");
	            commands.push ("-sdk");
	            commands.push ("iphonesimulator");
			}
			ProcessUtil.runCommand(targetPath, "xcodebuild", commands);
			//------------------------------------
			
			
			//-------- Run Xcode Project ---------
			if(deviceTarget.getSetting(Target.RUN_WHEN_FINISHED) == "true")
			{
				var launcher:String = libPath + "/bin/ios-sim";
				Sys.command ("chmod", [ "+x", launcher ]);
				
				var family:String = "iphone";
				if(deviceTarget.getSetting(AppleTarget.SIMULATOR_TYPE) == "ipad")
					family = "ipad";
				
				ProcessUtil.runCommand ("", launcher, [ "launch", FileSystem.fullPath (targetPath + "/build/Debug-iphonesimulator/" + appName + ".app"), "--family", family ] );
		
			}
				//------------------------------------
		}
		catch(error:String)
		{
			neko.Lib.println(error);
		}
	}
	
}