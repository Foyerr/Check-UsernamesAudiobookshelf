# Check-UsernamesAudiobookshelf

What happened?
I noticed that when hitting the authentication endpoint, there's a consistent difference in response time between valid and invalid usernames. This can be used to enumerate which usernames exist in the system.

I tested this by sending 100 requests per username and taking the median response time. Here’s a sample of the results (usernames have been anonymized):

Username MedianTimeMS

User1 25.69
User2 24.28
root 22.50
User3 22.26
john 5.13
guest 5.11
eric 5.10
admin 5.08
jane 5.08

As you can see, the first few usernames consistently take longer to respond, which suggests they're valid accounts. The rest respond much faster, because they don't exist.

This doesn’t apply to passwords, bcrypt appears to be in use, which handles comparison securely with a constant time comparison.

Might be worth taking a look to ensure the response timing is consistent regardless of whether the username exists, to prevent this kind of side-channel info leak.

What did you expect to happen?
Expect that the timing between nonvalid usernames and valid usernames to take the same amount of time as to not leak data.

Steps to reproduce the issue
https://github.com/Foyerr/Check-UsernamesAudiobookshelf
I have created a powershell script to demonstrate
provide the ip/hostname and a username if you wish, the script has a handful of test usernames including root

Audiobookshelf version
v2.16.2

How are you running audiobookshelf?
Windows Tray App

What OS is your Audiobookshelf server hosted from?
Windows

If the issue is being seen in the UI, what browsers are you seeing the problem on?
None

Logs
