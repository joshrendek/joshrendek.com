---
date: 2010-10-03T10:45:49Z
title: 'Ruby and Ebay: Get list prices'
---

I'll eventually be turning my ruby ebay work into a gem, but for now here are little snippets:

Please note that this code automagically takes care of things like 4x SOMETHING -- it'll take the current list price and divide by four, if you don't want that functionality, remove the divider. You also need rest-open-uri and hpricot for gems.

To get a list of prices:

{{< highlight ruby >}}
def self.get_search_results(query)
            # API request variables
            endpoint = 'http://svcs.ebay.com/services/search/FindingService/v1';  # URL to call
            version = '1.0.0';  # API version supported by your application
            appid = 'YOUR APP ID';  # Replace with your own AppID
            globalid = 'EBAY-US';  # Global ID of the eBay site you want to search (e.g., EBAY-DE)
            safequery = URI.encode(query);  # Make the query URL-friendly

            # Construct the findItemsByKeywords HTTP GET call
            apicall = "#{endpoint}?";
            apicall += "OPERATION-NAME=findItemsByKeywords";
            apicall += "&SERVICE-VERSION=#{version}";
            apicall += "&SECURITY-APPNAME=#{appid}";
            apicall += "&GLOBAL-ID=#{globalid}";
            apicall += "&keywords=#{safequery}";
            apicall += "&paginationInput.entriesPerPage=25";

            res = ""

            open( apicall ).each { |s| res << s }
            prices = []


            doc = Hpricot.parse(res)
            (doc/:item).each do |x|

                divider = 1
                get_count = (x/:title).inner_html.scan(/[0-9]/).first
                p "#{(x/:title).inner_html}"
                if !get_count.nil?
                    divider = get_count.to_i
                end
                prices << (x/:sellingstatus/:currentprice).inner_html.to_f/divider
            end

            prices
end
{{< / highlight >}}
