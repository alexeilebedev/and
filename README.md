This is a perl script that creates/runs android apps.
It's intended as a learning tool, and to be built upon.
Read it. Change it.

I started with this project: https://github.com/czak/minimal-android-project.git (thank you)

My steps on MacOS:
1. Install brew:
~~~
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew install gradle
~~~

2. Configure environment:
~~~
cat >> ~/.bashrc <<EOF
ANDROID_HOME=$HOME/Library/Android/sdk
export ANDROID_HOME
PATH=$PATH:$ANDROID_HOME/platform-tools
EOF
. ~/.bashrc
~~~

3. Download android sdk
How? I already had it, courtesy of Android Studio. On my mac, it's in $HOME/Library/Android/sdk

4. Run and.pl. This creates a new git repo as well. 
~~~
./and.pl com.alexeilebedev.helloworld create build start
~~~

5. Live and prosper. The newly created application is stand-alone and includes a copy of and.pl
~~~
cd helloworld
<edit files>
./and.pl com.alexeilebedev.helloworld reinstall
~~~
