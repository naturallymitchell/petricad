import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'filemgr.dart';
import 'default-vscode-theme.dart';

class ThemesTheme{
    ThemeData libThemeData;

    ThemesTheme({
        required this.libThemeData
    });
}

class ThemesProvider extends ChangeNotifier{

    // map for all loaded themes
    Map<String, ThemesTheme> _themes = {};

    // default theme
    static const String _defaultThemeKey = "Owlet (Palenight)";

    // current theme
    String _activeThemeKey = _defaultThemeKey;

    // -------------------------------------- Public calls ------------------------ //

    // set theme
    setTheme(String name){
        ThemesTheme? newTheme = _themes[name];

        if(newTheme != null){
            _activeThemeKey = name;
            notifyListeners();
        }   
        else{
            return;
        }
    }

    // get current theme
    ThemesTheme getTheme(){
        // returns the current theme or a guaranteed default theme if the former is null
        return _themes[_activeThemeKey] ?? (_themes[_defaultThemeKey]!);
    }

    // get theme list
    List<String> getThemeNameList(){
        List<String> list = [];

        for(var theme in _themes.keys){
            list.add(theme);
        }
        
        return list;
    }

    // constructor
    ThemesProvider({required String themesDir, required String startTheme}){
        if(!(Directory(themesDir).existsSync())){
            exit(-1);
        }

        _activeThemeKey = startTheme;

        // for every json theme file in the themes directory
        for(var file in Directory(themesDir).listSync(followLinks: false, recursive: false)){
            String themeString = File(file.path).readAsStringSync();
            late Map<String, dynamic> theme;
            
            try{
                // special chars                 
                themeString = themeString.replaceAllMapped(RegExp(r"(://)|[$]", multiLine: false, caseSensitive: false), 
                    (Match m) => ""
                );

                // remove comments
                themeString = themeString.replaceAllMapped(RegExp(r"//.*", multiLine: false, caseSensitive: false), 
                    (Match m) => ""
                );

                // remove leading commas on last child of array/object
                themeString = themeString.replaceAllMapped(RegExp(r",([\n\s]+(\}|\]))", multiLine: true, caseSensitive: false), 
                    (Match m) => "${m[1]}"
                );
                
                theme = jsonDecode(themeString);
            }
            catch(e){
                continue;
            }

            var name = theme["name"] ?? p.basenameWithoutExtension(file.path);

            

            // save theme in array with the key same as "name" in json or filename without extension
            _themes[name] = ThemesTheme(
                libThemeData: ThemeData(

                    brightness: theme["type"] == "dark" ? Brightness.dark : Brightness.light,
                    // appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
                    // scaffoldBackgroundColor: const Color(0xFF121212),

                    backgroundColor: _getThemeColor(theme,"editor.background"),
                    primaryColor:   _getThemeColor(theme,"editor.background"),

                    hoverColor:     _getThemeColor(theme,"activityBar.foreground"),
                    focusColor:     _getThemeColor(theme,"activityBar.foreground"),
                    highlightColor: _getThemeColor(theme,"activityBar.foreground"),
                    dividerColor:   _getThemeColor(theme,"activityBar.inactiveForeground"),

                    // iconTheme: const IconThemeData().copyWith(color: const Color(0xFF4d4f5d)),
                    iconTheme: IconThemeData(
                        color: _getThemeColor(theme,"activityBar.inactiveForeground"),
                        opacity: 100,
                        size: 25,
                    ),

                    tooltipTheme: TooltipThemeData(
                        textStyle: TextStyle(
                            color: _getThemeColor(theme,"editor.foreground"),
                            fontSize: 13.0,
                            fontWeight: FontWeight.normal,
                            letterSpacing: 0
                        ),
                        decoration: BoxDecoration(
                            color: _getThemeColor(theme,"sideBar.background"),
                            border: Border.all(
                                width: 1,
                                color: _getThemeColor(theme,"activityBar.inactiveForeground"),
                            )
                        ),
                    ),

                    colorScheme: ColorScheme(
                        brightness: theme["type"] == "dark" ? Brightness.dark : Brightness.light,
                        
                        error: _getThemeColor(theme,"sideBar.background"),
                        onError: _getThemeColor(theme,"errorForeground"),

                        background: _getThemeColor(theme,"editor.background"),
                        onBackground: _getThemeColor(theme,"editor.foreground"),
                        inversePrimary: _getThemeColor(theme,"list.highlightForeground"),

                        primary: _getThemeColor(theme,"sideBar.background"),
                        onPrimary: _getThemeColor(theme,"sideBar.foreground"),

                        secondary: _getThemeColor(theme,"statusBar.background"),
                        onSecondary: _getThemeColor(theme,"statusBar.background"),

                        tertiary: _getThemeColor(theme,"list.activeSelectionBackground"),
                        onTertiary: _getThemeColor(theme,"list.activeSelectionForeground"),

                        surface: _getThemeColor(theme,"editor.background"),
                        onSurface: _getThemeColor(theme,"editor.foreground"),

                    ),

                    inputDecorationTheme: InputDecorationTheme(
                        filled: true,
                        fillColor: _getThemeColor(theme,"editor.background"),

                        hintStyle: TextStyle(
                            color: _getThemeColor(theme,"editor.foreground"),
                            fontSize: 13.0,
                            letterSpacing: 0,
                            fontWeight: FontWeight.normal
                        ),
                        labelStyle: TextStyle(
                            color: _getThemeColor(theme,"editor.foreground"),
                            fontSize: 13.0,
                            letterSpacing: 0,
                            fontWeight: FontWeight.normal
                        ),
                    ),

                    textTheme: TextTheme(
                        button: TextStyle(
                            color: _getThemeColor(theme,"editor.foreground"),
                            fontSize: 13.0,
                            letterSpacing: 0,
                            fontWeight: FontWeight.normal
                        ),
                        subtitle1: TextStyle(
                            color: _getThemeColor(theme,"editor.foreground"),
                            fontSize: 13.0,
                            letterSpacing: 0,
                            fontWeight: FontWeight.normal
                        ),
                        subtitle2: TextStyle(
                            color: _getThemeColor(theme,"editor.foreground"),
                            fontSize: 10.0,
                            fontWeight: FontWeight.normal
                        ),
                    )
                )
            );
        }
    }

    // -------------------------------------- Private calls ----------------------- //

    // converto color in hex string "#ffffff" to integer
    Color _hex2Color(String hex){
        int num = 0;
        
        // #FFFFFFFF case
        if(hex.length >= 8){
            hex = hex.replaceAll("#", "");
            num = int.parse(hex, radix:16);
            num = ((0xffffff00 & num) >> 8) | ((0x000000ff & num) << 3*8);
        }
        // #FFFFFF case
        else{
            hex = hex.replaceAll("#", "FF");
            num = int.parse(hex, radix:16);
        }
        
        return Color(num);
    }

    // get color from json file an return as Color
    Color _getThemeColor(Map<String, dynamic> theme, String name){
        String? hexColor = theme["colors"] == null ? null : theme["colors"][name];

        if(hexColor == null){
            return defaultVscodeTheme[name] ?? Colors.black;
        }
        else{
            return _hex2Color(hexColor);
        }
    }

}


