#!/usr/local/bin/perl
# Alexei Lebedev, Mar 10, 2018
use strict;
my $thisfile=$0;
my $usage="Usage: $0 <appname> [create | build | install | reinstall | run | stop]*
e.g. $0 com.alexeilebedev.helloworld create build run";

sub checkenv($) {
    foreach my $x (@_) {
	$ENV{$x} or die "ERROR: please define environment variable $x\n";
    }
}

sub checkexec(@) {
    foreach my $x (@_) {
	`which $x` ne "" or die "ERROR: command $x is not in the PATH.\n";
    }
}

sub maybe_cd_app($) {
    my ($app)=$_[0];
    my $appname=appname($app);
    if (-d $appname) {
	chdir($appname) or die "chdir $appname: $!\n";
    }
    print "directory changed to $appname\n";
}

sub string_to_file($$) {
    my ($str,$file)=@_;
    open(F,'>',$file) or die "$file: $!\n";
    print F $str;
    close(F);
}

# com.alexeilebedev.and -> and
sub appname($) {
    my $x=$_[0];
    $x=~s/.*\.//;
    return $x;
}

# and -> And
sub ucname($) {
    my $x=$_[0];
    if ($x =~ /^(.)(.*)/) {
	$x = uc($1) . $2;
    }
    return $x;
}

# com.alexeilebedev.and -> and/src/main/java/com/alexeilebedev/and
sub javadir($) {
    my $x=$_[0];
    my $ret=appname($x) . "/src/main/java/$x";
    $ret =~ s/\./\//g; # replaces . with /
    return $ret;
}
    
sub create($) {
    my $app=$_[0];
    my $name=appname($app);
    my $ucname=ucname($name);
    !-d $name or die "direcrtory $name seems to already exist\n";
    print "and.create"
	. "  app:$app"
	. "  name:$name"
	. "  ucname:$ucname"
	. "\n";
    mkdir($name);
    my $build = qq!
apply plugin: 'com.android.application'

buildscript {
    repositories {
        jcenter()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:2.3.0'
    }
}

apply plugin: 'com.android.application'

android {
    compileSdkVersion 26
    buildToolsVersion '25.0.0'
}
!;
    string_to_file($build,"$name/build.gradle");
    mkdir("$name/src");
    my $manifest = qq!<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="$app">
    <application android:label="$ucname">
        <activity android:name="Main">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>!;
    system("mkdir -p $name/src/main")==0 or die "$?";
    string_to_file($manifest,"$name/src/main/AndroidManifest.xml"); # name must be just so
    my $code = qq%
package $app;
import android.app.Activity;
import android.os.Bundle;
import android.widget.TextView;

public class Main extends Activity {
    \@Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        TextView textview = new TextView(this);
        textview.setText("Hello from $app!");
        setContentView(textview);
    }
}
%;
    string_to_file(qq!.gradle
build
!, "$name/.gitignore");
    my $javadir=javadir($app);
    system("mkdir -p $javadir")==0 or die "$?";
    string_to_file($code, $javadir . "/Main.java");
    system("
	   cp $thisfile $name/and.pl
	   cd $name
	   git init .
	   git add .
	   git commit -am '$app -- initial commit'
	   ")==0 or die $?;
    print "created app $app and git repo under $name.\n";
}

sub main() {
    # execute commands provided on command line
    checkenv("ANDROID_HOME");
    checkexec("java", "adb", "gradle");
    my $app=shift @ARGV;
    $app=~ /(^com\.|^org\.)/ or die "expected app name to start with com. or org.\n\n$usage\n";
    my $appname=appname($app);
    while ((my $cmd=shift @ARGV)) {
	if ($cmd eq "create") {
	    create($app);
	} elsif ($cmd eq "start") {
	    maybe_cd_app($app);
	    system("adb shell am start -a android.intent.action.MAIN -n $app/.Main -S");
	} elsif ($cmd eq "stop") {
	    maybe_cd_app($app);
	    system("adb shell am force-stop $app");
	} elsif ($cmd eq "build") {
	    maybe_cd_app($app);
	    system("gradle installDebug");
	} elsif ($cmd eq "reinstall") {
	    maybe_cd_app($app);
	    system("stop");
	    print "uninstalling\n";
	    system("adb -d uninstall $app");
	    print "installing\n";
	    system("adb -d install build/outputs/apk/debug/app-debug.apk");
	}
    }
}
	
main();
exit 0;
