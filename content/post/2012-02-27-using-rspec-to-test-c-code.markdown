---
date: 2012-02-27T00:00:00Z
title: Using RSpec to test C code
url: /2012/02/using-rspec-to-test-c-code/
---

I was working on a C assignment for school and wanted an easy way to test the output of a program running against multiple test cases.

Using RSpec I came up with the following spec:

{{< highlight ruby >}}
describe "Calculator "do
    before(:all) do
        `make clean; make;`
    end
    it "should accept p1" do
        `./calc < testing/p1.cal`.should include "accept"
    end

    it "should reject p2" do
        `./calc < testing/p2_err.cal`.should include "reject"
    end

    it "should reject p3" do
        `./calc < testing/p3_err.cal`.should include "Variable a duplicate declaration"
    end

    it "should reject p4" do
        `./calc < testing/p4_err.cal`.should include "Variable b uninitiated at line 5"
    end

    it "should accept p5" do
        `./calc < testing/p5.cal`.should include "accept"
    end

    it "should accept p6" do
        `./calc < testing/p6.cal`.should include "accept"
    end

    it "should reject p7" do
        `./calc < testing/p7_err.cal`.should include "syntax error at line 9"
    end

    it "should reject p8" do
        `./calc < testing/p8_err.cal`.should include "Variable d undeclared"
    end

    it "should reject p9" do
        `./calc < testing/p9_err.cal`.should include "divide by zero at line 7"
    end

end

{{< / highlight >}}


I was then able to run all my tests with a single command and get informative output.


{{< highlight bash >}}
.........

Finished in 0.49705 seconds
9 examples, 0 failures

{{< / highlight >}}
