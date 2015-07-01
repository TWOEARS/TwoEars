Two!Ears Startup
================

Formely known as **Two!Ears Git Combiner**.

This tool, in particular the `setupRepoConfig()` function will help you setup the
Matlab pathes / Two!Ears git repositories according to your needs.


## Usage as Two!Ears model user

You don't have to run any function of this folder yourself, use the `startTwoEars()`
function instead. What you have to set before are all the pathes of the single
Two!Ears model parts. To do this create a file `TwoEarsPaths.xml` in the same
folder as the `startTwoEars()` function is located in which you specify all the
pathes of the different Two!Ears model parts. This file could look like this
one, which is also provided with the file `TwoEarsPaths_Example.xml`.

```xml
<?xml version="1.0" encoding="utf-8"?>
<repoPaths>
    <binaural-simulator>~/git/twoears/binaural-simulator</binaural-simulator>
    <sofa>~/git/twoears/SOFA</sofa>
    <data>~/git/twoears/twoears-data</data>
    <tools>~/git/twoears/twoears-tools</tools>
    <ssr>~/git/twoears/twoears-ssr</ssr>
</repoPaths>
```


## Usage as a Two!Ears model developer


All steps above, as you'll also be a user ;).  

Create an xml file with arbritrary name (for example `yourConfig.xml`) with a structure
like in the following example:

```xml
<?xml version="1.0" encoding="utf-8"?>
<requirements>
    <TwoEarsPart sub="src" startup="startBinauralSimulator">binaural-simulator</TwoEarsPart>
    <TwoEarsPart sub="API_MO" startup="SOFAstart" branch="BRIRs">sofa</TwoEarsPart>
    <TwoEarsPart startup="startData" branch="master">data</TwoEarsPart>
    <TwoEarsPart sub-all="src" startup="startTools" >tools</TwoEarsPart>
</requirements>
```

This ensures the following actions:
 
* For each `TwoEarsPart`, the according path will be added temporarily to matlab.
* If you put a `sub` attribute to the requirement, the specified subpath will be added instead of the repository home path.
* If you put a `sub-all` attribute to the requirement, the specified subpath and all subdirectories will be added instead of the repository home path.
* If you put a `branch` attribute to the requirement, it will be checked that your repository is checked out into that specific branch and warn if otherwise.
Note, that the default behavior is checking for no branch at all. This ensures
that the `startTwoEars()` function also works if the model is downloaded as a
zip-file without using git. This means if you want to ensure the usage of the
master branch you have to explicitly state `branch="master"`.
* If you put a `startup` attribute to the requirement, the respective function will be executed after adding the path of this requirement.

As first action in your script, call `startTwoEars( 'yourConfig.xml' )`.
