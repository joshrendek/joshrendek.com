---
categories: ruby jruby testing
comments: true
date: 2013-07-17T00:00:00Z
title: From 0 to Testing on Windows with JRuby
url: /2013/07/from-0-to-testing-on-windows-with-jruby/
---

Testing is one of the most important parts of software development and helps to ensure
bugs don't get into production and that code can be refactored safely.
If you're working on a team with multiple people with different skill sets,
you might have people doing testing who only know windows and development is only
using OSX or Linux. We want everyone to be able to test - someone in QA who is familiar
with Windows shouldn't have to throw away all that knowledge, install Linux, and start from scratch.
Enter JRuby and John.

John is our tester and he is running windows. He wants to help make sure that when a user
goes to `http://google.com/` that a button appears with the text "Google Search".
The quick way to do this is to open his browser, navigate to `http://google.com/`
glance through the page for the button and confirm that its there.
John has a problem though, he has 30 other test cases to run and the developers are pushing code to the frontpage
several times a day; John now has to continously do this manually everytime code is touched and
his test load is piling up.

So let's help John out and install [Sublime Text 2](http://sublimetext.com/2) and [JRuby](http://jruby.org/).

![](/images/jrubytesting/download-sublime.png)

Start by downloading the 64-bit version of Sublime Text.
Make sure to add the context menu when going through the install process.

![](/images/jrubytesting/slt-setup.png)

Now we'll visit the JRuby homepage and download the 64 bit installer.

![](/images/jrubytesting/dl-jruby.png)

Go through the installer and let JRuby set your path so you can access ruby from `cmd.exe`

![](/images/jrubytesting/jruby-path.png)

Now when we open `cmd.exe` and type `jruby -v` we'll be able to see that it was installed.

![](/images/jrubytesting/jruby-cmd.png)

Now that we have our tools installed lets setup our test directory on the Desktop.
Inside our `testing` folder we'll create a folder called `TestDemo` for our tests for the Demo project.

![](/images/jrubytesting/testdemo-folder.png)

Next we'll open Sublime Text and go to `File > Open Folder` and navigate to our `TestDemo` folder and hit open.

![](/images/jrubytesting/slt-openfolder.png)

Now we can continue making our directory structure inside Sublime Text. Since we're going to use `rspec`
we need to create a folder called `spec` to contain all of our tests. Right click on the `TestDemo` in the
tree navigation and click `New Folder`.

![](/images/jrubytesting/slt-newfolder.png)

Call the folder `spec` in the bottom title bar when it prompts you for the folder name.

Next we'll create our Gemfile which will declare all of our dependencies - so make a file in the project root called
`Gemfile` and put the our dependencies in it:

``` ruby
source "https://rubygems.org"

gem "rspec"
gem "selenium"
gem "selenium-webdriver"
gem "capybara"

```

Once we have that file created, open `cmd.exe` and switch to your project's root directory.

Type `jgem install bundler` to install `bundler` which manages ruby dependencies.

![](/images/jrubytesting/bundler.png)

While still at the command prompt we're going to `bundle` to install our dependencies:

![](/images/jrubytesting/bundle.png)

After that finishes we need to run one last command for `selenium` to work properly: `selenium install`

![](/images/jrubytesting/selenium-install.png)

We also need a `spec_helper.rb` file inside our `spec` directory.

``` ruby
require "rspec"
require "selenium"
require "capybara/rspec"

Capybara.default_driver =  :selenium
```

We've now setup our rspec folders, our Gemfile with dependencies, and installed them. Now we can write
the test that will save John a ton of time.

Chrome comes with a simple tool to get XPath paths so we're going to use that to get the XPath
for the search button. Right click on the "Google Search" button and click `Inspect element`

![](/images/jrubytesting/google-inspect.png)

Right click on the highlighted element and hit `Copy XPath`.

![](/images/jrubytesting/google-xpath.png)

Now we're going to make our spec file and call it `homepage_spec.rb` and locate it under `spec\integration`.

Here is a picture showing the directory structure and files:
![](/images/jrubytesting/homepage-spec.png)


Here is the spec file with comments explaining each part:
``` ruby
# This loads the spec helper file that we required everything in
require "spec_helper"

# This is the outer level description of the test
# For this example it describes going to the homepage of Google.com
# Setting the feature type is necessary if you have
# Capybara specs outside of the spec\features folder
describe "Going to google.com", :type => :feature do

  # Context is like testing a specific component of the homepage, in this case
  # its the search button
  context "The search button" do
    # This is our actual test where we give it a meaningful test description
    it "should contain the text 'Google Search'" do
      visit "http://google.com/" # Opens Firefox and visits google
      button = find(:xpath, '//*[@id=gbqfba"') # find an object on the page by its XPath path
      # This uses an rspec assertion saying that the string returned
      # by button.text is equal to "Google Search"
      button.text.should eq("Google Seearch")

    end
  end

end

```


Now we can tab back to our `cmd.exe` prompt and run our tests!
`rspec spec` will run all your tests under the `spec` folder.
![](/images/jrubytesting/rspec-spec.png)


### Things to take note of

This example scenario is showing how to automate browser testing to do end-to-end tests on a product using rspec.
This is by no means everything you can do with rspec and ruby - you can SSH, hit APIs and parse JSON, and do anything
you want with the ability to make assertions.

A lot is going on in these examples - there are plenty of resources out there on google and other websites
that provide more rspec examples and ruby examples.

We also showed how to add dependencies and install them using `bundler`.
Two of the best resources for finding libraries and other gems is
[RubyGems](http://rubygems.org/) and [Ruby-Toolbox](http://ruby-toolbox.com/) - the only thing to take note of
is anything saying to be a native C extension (they won't work with JRuby out of the box).

My last note is that you also need to have firefox installed as well - Selenium will work with Chrome but I've found it to be a
hassle to setup (and unless you really need Chrome), the default of Firefox will work great.
