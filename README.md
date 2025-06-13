### AxM_API
Automation of creating and validing tokens when working with the AxM API based on the [script](https://github.com/bartreardon/macscripts/blob/master/create_client_assertion.sh) provided by [Bart Reardon](https://github.com/bartreardon)

<p align="center">
<img width="512" alt="CantScript Logo" src="https://github.com/cantscript/LocalJamfSchoolVariables/blob/main/CantScript_Full_DotComV7.png">
</p>

To find out more about this project check out the post ["Automating Token Generation for Apple School Managers New API"](https://cantscript.com/posts/automating-token-generation-for-apple-school-managers-new-api/) on my blog [CantScript.com](https://cantscript.com)

-----
### The Solution
1. [A Script](https://github.com/cantscript/AxM_API/blob/main/AxM_API/AutomationScripts/create_client_assertion.sh) that only deals with creating the `Client Assertion`
2. Saves the `Client Assertion` to a text file, along with a date/time stamp 180 days later
3. [A second Script](https://github.com/cantscript/AxM_API/blob/main/AxM_API/AutomationScripts/create_access_token.sh) that only handle the creation of the `Access Token`
4. Saves the `Access Token` to a text file, along with a timestamp 60 mins later
5. Should an `Access Token` not exist, the second script will create an `Access Token` providing the  `Client Assertion` is still valid based on its date/time stamp 
6. Should there be an `Access Token` but its not valid based on its timestamp, the second script will create a new valid `Access Token`, again providing the `Client Assertion` is still valid based on its date/time
7. Enables two lines of code in the actual API script that creates/checks/renews the `Access Token` and saves the value into a variable for use in that script

This is all contained in a folder structure so as long as you add the scripts that interact with the API in the root of this folder, you only need to add the `values` you need from Axm to the _Create Client Assertion_ and _Create Access Token_ scripts once and no other variables are needed to make the automation work.  

-----
### Configuring the Automation
First things first, if you haven't already go and read [Barts blog](https://bartreardon.github.io/2025/06/11/using-the-new-api-for-apple-business-school-manager.html) so that you know how to configure ASM. From ASM you'll need
* `The Private Key File` which will end in .pem <br>
* `Client ID` <br>
* `Key ID`

**Step 1** <br>
* Download the `AxM_API` folder from the GitHun repo.

It doesn't matter where this folder lives on the device as long as you know where you keep it as this is going to become the working folder for all of your ASM API scripts

**Step 2** <br>
Take your `Private Key File` and move it into the `AxM-API/AxMCert` folder

**Step 3** <br>
* Open `AxM-API/AutomationScript/create_client_assertion.sh` in a text/code editor <br>
* Enter the name of your `Private Key File` (so for example `myPrivateKey.pem`, not the location of the file) into the `private_key_file` variable <br>
* Enter your `Client ID` into the `client_id` variable <br>
* Enter your `Key ID` into the `key_id` variable <br>
* Save and close

**Step 4** <br>
* Open `AxM-API/AutomationScript/create_access_token.sh` in a text/code editor <br>
* Enter your `Client ID` into the `client_id` variable <br>
* Comment out either `scope="school.api"` or `scope="business.api"` depending on if you are interacting with ASM or ABM <br>
* Save and close

**Step 5** <br>
* Run `AxM-API/AutomationScript/create_client_assertion.sh`

-----
### Using the Code

Any script that you want to use that interacts with the AxM API needs save to the root of the `AxM_API` folder. 

I've given a simple example script within the `AxM_API` folder. 

Your scripts just need the following two lines at the top

~~~
./AutomationScripts/create_access_token.sh
accessToken=$(awk -F': ' '/^AccessToken:/ {print $2}' ./Tokens/access_token_format.txt)
~~~

Then you will use the `accessToken` variable as the bearer token in a call. Below is a simple example. 

~~~
curl "https://api-school.apple.com/v1/mdmServers" -H "Authorization: Bearer ${accessToken}"
~~~

Notice that as part of the setup with didn't run the `create_access_token.sh`? Thats becuase on the first run of any script, the automation will see that there isn't one and will generate it on the fly for you.  

The next part is up to you! How you interact with AxM and the automations and workflow you create is actually the hard part and the part that gets the job done. 

If you haven't already seen, here are the [Apple Documents for the [ASM Endpoints](https://developer.apple.com/documentation/appleschoolmanagerapi) or [ABM Endpoints](https://developer.apple.com/documentation/applebusinessmanagerapi)


---
### A Quick Note

Although the scripts take care of keeping the `Access Token` valid, I didn't actually build in any "self renewal" of the `Client Assertion`. If this becomes invalid due to being over 180 days old, everything will just exit and error out. 

So if you need to renew this, run `AxM-API/AutomationScript/create_client_assertion.sh` again. 

_"You took the time to self renew the `Access Token` so why not the `Client Assertion`"_. Great Question! I just didn't, at least not today. Maybe next time I have a few minutes and I don't have a project Im not working on
