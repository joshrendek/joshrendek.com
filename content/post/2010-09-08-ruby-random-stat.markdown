---
date: 2010-09-08T12:24:40Z
title: 'Ruby: random stat'
wordpress_id: 403
wordpress_url: http://bluescripts.net/?p=403
---

I have a program that takes a block of texts and then counts the most popular occurrences of words in that text. Processed a 680,354 character string in about 30 minutes on 2 Core i7s and an SSD. Probably could be optimized a bit I think.

Snippet:

<pre lang="ruby">
def get_keywords_for_content(content, n)
    content = content.gsub(/<\/?[^>]*>/, "")
    words = content.split(/ /)
    # clean up the matches
    words.collect! { |x|
      begin
        x.downcase.match(/[a-zA-Z0-9]+/)[0].chomp
      rescue
        #print "Failed on: #{x} - #{e}\n"
      end
    }
    words.compact!

    occurrences = []
    for w in words
      #p "#{w}: " + self.count_occurrences(w, content).to_s
      occurrences << [count_occurrences(w, content), w] if !@@exclude.include?(w)
    end

    keywords = []

    counter = 0
    for o in occurrences.uniq.sort.reverse
      if counter == n then
        break
      end

      #p "#{o[0]} => #{o[1]}"
      keywords << o[1]

      counter+=1
    end


    return keywords
  end
</pre>
