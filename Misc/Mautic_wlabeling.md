
https://github.com/nickian/mautic-whitelabeler
While trying nickian php script, faced many errors and issues, but this make sense to do manually.


I was able to change the branding to my client's brand. Though i didn't remove any Mautic's credit inside the codes. Plus,
Disclaimer : Dont sell that product under your name. Do it for your client told him the work belongs to Mautic community.
The lines may change version to version

Here is the instructions how i changed the name. Hope that helps other too.

"To remove Footer from Dashboard (Copy rights Mautic), open base.html.php from here - /var/www/html/manutic215/app/bundles/CoreBundle/Views/Default
--- Disable or Remove line 42-47"

"To change page title (From Mautic to Your Brand) on Dashboard (2), open head.html.php from here - /var/www/html/manutic215/app/bundles/CoreBundle/Views/Default
---- Replace the 'Mautic' by 'Your Brand' on line 12"

"To change Favicon on Dashboard, open head.html.php from here - /var/www/html/manutic215/app/bundles/CoreBundle/Views/Default
---- Replace the Favicon by the desired icon file/image name on line 14, 15 and 16"

"To change logo (from Mautic to Your Brand) on Dashboard, open and look in index.html.php from here - /var/www/html/manutic215/app/bundles/CoreBundle/Views/LeftPanel

"To changs of 403, 404, 500 Error's Bot icon and texts, open base.html.php from here - /var/www/html/manutic215/app/bundles/CoreBundle/Views/Error
---- In line 52 replace Mautibot by Your Brand
---- In line-54 change the href value to this - http://www.yoursite.com/report-issue"

"To changs of 403, 404, 500 Exception's Bot icon and texts, open base.html.php from here - /var/www/html/manutic215/app/bundles/CoreBundle/Views/Error
---- Replace line-47 by this - <img class=""img-responsive"" src=""getUrl('media/images/logo_login.png') ?>"" alt="Logo"/>
---- In line 52 replace Mautibot by Your Brand
---- In line-55 change the href value to this - http://www.yoursite.com/report-issue"

"To change Login Form Title, Favicon, Logo (Mautic to Your Brand) and Footer, open base.html.php from here - /var/www/html/manutic215/app/bundles/UserBundle/Views/Security
---- Change 'Mautic' to 'Your Brand' in line - 15
---- Replace line-17 and 18 by this - <link rel=""icon"" type=""image/x-icon"" href=""getUrl('media/images/logo.png') ?>"" />

getUrl('media/images/logo.png') ?>"" /> ---- Replace line-30 to 39 by this - getUrl('media/images/logo.png') ?>"" class=""login-page-logo"" alt="Your Brand"/> ---- After applying the above changes. Remove line-42 to 46 to remove Copyright Mautic from the login page. Or look for the below code and delete them ---
"To change the Mauticbot icon from Notifications/Message, open noresults.html.php from here - /app/bundles/CoreBundle/Views/Helper
---- Replace line - 12 by this -
<img class=""img-responsive"" src=""getUrl('media/images/touchbaseicon-Light.png') ?>"" alt="Your Brand"/>"

"To change 'Mautic' from Password Reset email subject, open message.ini from here - /app/bundles/UserBundle/Translations/en_US/messages.ini
---- Replace ""Mautic"" by "Your Brand" in line-57"

Note that i copied these from a excel file. So u might see some extra double quotation marks. But if u understand what i said, that wont be any issue.
