# 2012R2HyperVHotfixes
Powershell script that will check for and/or install a custom list of 26 2012R2 Hyper-V hotfixes

### Synopsis
Powershell script will test if predefined list of 26 Hyper-V hotfixes are installed. Script is also capable of attempting to install list of 26 hotfixes

### Description
This Powershell script is statically pre-populated with a custom list of 26 hotfixes that I have tested and vetted in my Hyper-V environment.  These 26 are what I consider to be must haves on all Hyper-V deploments to ensure stability and maximum performance.  There are two primary functions Test-Hotfixes and Install-Hotfixes which repsecitvely check for and install the statically set list of 26 hotfixes.  For the Install piece to work you will need to download the .zip file containing the 26 hotfixes in the link below.  Not all hotfixes are applicable to all Hyper-V servers.  The script will simply attempt to install all of them, if a hotfix does not apply, the script will simply move on the next one in the list.  It is unlikely that all 26 will be required on your server so if Test-Hotfixes still shows a few missing after you attempt install, this is perfectly fine.

### Prerequisites
.NET 4.0 - the Expand-ZipFile portion of the script requires this
.zip file containing the 26 hotfixes: http://techthoughts.info/2012r2-hyper-v-hotfixes-list (if you wish the script to auto-install them for you)

### Example of how to run
Test-Hotfixes

Test-Hotfixes -prettyreport $true

Install-Hotfixes

### Author
Authors: Jake Morrison

http://techthoughts.info

### Notes

As with all things patching and hotfix related you are hereby cautioned to research each hotfix, it's prerequisites, purpose, and potential impact on your environment.  Test this in your lab before rolling to production, then test some more.  It's a good idea to be at the latest windows patch level on the Hyp prior to installing the hotfixes.  In my experience I have utilized the script below to apply the complete set to hundreds of Hyps with zero issues.  If a hotfix doesn't apply (many won't - for example - standalone non-clustered Hyps) the script simply carries on to the next hotfix.  Only those that are applicable to your Hyp will be applied.  Test!  I hope these improve your environment as much as they have mine.