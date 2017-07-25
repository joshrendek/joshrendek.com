---
categories: scala
comments: true
date: 2013-10-31T00:00:00Z
title: Parsing HTML in Scala
url: /2013/10/parsing-html-in-scala/
---

Is there ever a confusing amount of information out there on parsing HTML in Scala. Here is the list of possible ways I ran across:

* Hope the document is valid XHTML and use `scala.xml.XML` to parse it
* If the document isn't valid XHTML use something like TagSoup and hope it parses again
* Still think its valid XHTML? Try using `scalaz`'s XML parser

All of the answers I found on Google pointed to some type of XML parsing, which won't always work. Coming from Ruby I know there are tools out there like Selenium that can simulate a web browser for you and give you a rich interface to interact with the returned HTML.

So I went on Maven and found the two Selenium web drivers I wanted for my project and added them to my `libraryDependencies`:

{{< highlight scala >}}
    "org.seleniumhq.webdriver" % "webdriver-selenium" % "0.9.7376",
    "org.seleniumhq.webdriver" % "webdriver-htmlunit" % "0.9.7376"
{{< / highlight >}}

The project I'm working on is to parse Looking Glass websites for BGP information and AS peering, so I wanted to scrape the data. I also didn't want to have to use a full blown web browser (ala Selenium + Firefox for instance) - so I stuck with the `HtmlUnit` driver for the implementation.

Here is a quick code snippet that lets me grab AS #'s and Peer names from an AS:

{{< highlight scala >}}
val url = "http://example.com/AS" + as.toString

val driver = new HtmlUnitDriver
// Proxy for BetaMax when writing tests
if (_port != null) {
  driver.setProxy("localhost", _port)
}
driver.get(url)

val peers = driver.findElementsByXPath("//*[@id=\"table_peers4\"]/tbody/tr/td[position() = 1 or position() = 2]")

// zip up the list in pairs so List(a,b,c,d) becomes List((a,b), (c,d))
for(peer <- peers zip peers.tail) {
  println(peer)
}
{{< / highlight >}}

No XML to muck with and I get some nice selectors to query the document for. Remember if the source you want data from doesn't have an API, HTML is an API! Just be respectful of how you query and interact with them (ie: Don't do 100 requests/second, cache/record responses while writing tests, etc).
