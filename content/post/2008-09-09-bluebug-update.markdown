---
date: 2008-09-09T11:50:50Z
title: BlueBug Update
wordpress_id: 87
wordpress_url: http://bluescripts.net/2008/09/bluebug-update/
---

<p>I have released an update to BlueBug today that addresses the following issues that were brought up in comments:</p>  <ul>   <li><em><strong>v1.1 - </strong>9/9/2008 - RELEASED</em></li>    <ol>     <li>Added a line to the config.php to limit registered users to posting. Add $config[registered] = 1; in your config.php file to only allowed registered users (if upgrading).</li>      <li>Added a last insert id function to the Database class. </li>      <li>Administrators now get emails when new tickets have been added. </li>      <li>Assign to list for tickets now properly displays all users.</li>      <li>When a user is assigned to a ticket, they are notified by email.</li>      <li>Priority # changed to text for easier reading.</li>      <li>Users are now emailed when their ticket is closed, if they are registered.</li>      <li>There is now a user administration area in the admin panel.</li>   </ol> </ul>
