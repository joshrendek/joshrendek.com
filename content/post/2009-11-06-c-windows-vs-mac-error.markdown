---
date: 2009-11-06T13:08:55Z
title: 'C++ not reading in integers: Windows vs Mac error?'
wordpress_id: 293
wordpress_url: http://bluescripts.net/?p=293
---

Well I was doing some homework today in XCode and ran across a strange error...

Assume the first line of the file is an integer, lets say 127
<pre>ifstream inFile;
int number;
inFile >> number;</pre>
You would think, on both windows and mac this would store 127 in number.
Only on windows. On my mac it would read in 0 as the value.

On mac (specifically in xcode) to get that number...
<pre>ifstream inFile;
int num;
string temp_num;
inFile >> temp_num;
num = atoi(temp_num.c_str());</pre>
Interesting little bug, or perhaps design choice?
