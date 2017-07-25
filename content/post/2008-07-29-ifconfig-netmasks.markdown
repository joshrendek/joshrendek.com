---
date: 2008-07-29T08:27:55Z
title: ifconfig & Netmasks
wordpress_id: 25
wordpress_url: http://bluescripts.net/?p=25
---

<div class="entry">

Whenever moving IPs around on servers I always find myself looking up the hex for a netmask.

Ever run into this
<pre class="highlightcode">$ ifconfig

inet xxxxxxxxxxx netmask 0xfffffff0 broadcast xxxxxxxxxxxxxx</pre>
And need to know what the fffffff0 was for Here it is:
<table border="1" cellspacing="5" cellpadding="3">
<tbody>
<tr>
<td align="middle"><strong>Dotted
Decimal</strong></td>
<td align="middle"><strong>Hex</strong></td>
<td align="middle"><strong>Number of
Addresses</strong></td>
</tr>
<tr>
<td align="middle">255.0.0.0</td>
<td align="middle">FF000000</td>
<td align="middle">16777214 (16777216-2)</td>
</tr>
<tr>
<td align="middle">255.255.0.0</td>
<td align="middle">FFFF0000</td>
<td align="middle">65534 (65536-2)</td>
</tr>
<tr>
<td align="middle">255.255.255.0</td>
<td align="middle">FFFFFF00</td>
<td align="middle">254 (256-2)</td>
</tr>
<tr>
<td align="middle">255.255.255.128</td>
<td align="middle">FFFFFF80</td>
<td align="middle">126 (128-2)</td>
</tr>
<tr>
<td align="middle">255.255.255.192</td>
<td align="middle">FFFFFFC0</td>
<td align="middle">62 (64-2)</td>
</tr>
<tr>
<td align="middle">255.255.255.224</td>
<td align="middle">FFFFFFE0</td>
<td align="middle">30 (32-2)</td>
</tr>
<tr>
<td align="middle">255.255.255.240</td>
<td align="middle">FFFFFFF0</td>
<td align="middle">14 (16-2)</td>
</tr>
<tr>
<td align="middle">255.255.255.248</td>
<td align="middle">FFFFFFF8</td>
<td align="middle">6 (8-2)</td>
</tr>
<tr>
<td align="middle"><span style="color: #808080;">255.255.255.252 *</span></td>
<td align="middle"><span style="color: #808080;">FFFFFFFC *</span></td>
<td align="middle"><span style="color: #808080;">2 (4-2) *</span></td>
</tr>
</tbody></table>
</div>
