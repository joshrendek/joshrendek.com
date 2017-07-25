---
date: 2011-11-09T00:00:00Z
title: 'Rails: Rendering a view in a model to generate a pdf'
url: /2011/11/rails-rendering-a-view-in-a-model-to-generate-a-pdf/
---

{{< highlight ruby >}}
class RenderHelper
  class << self
    def render(assigns, options, request = {})
      request = {
        "SERVER_PROTOCOL" => "http",
        "REQUEST_URI" => "/",
        "SERVER_NAME" => "localhost",
        "SERVER_PORT" => 80
      }.merge(request)

      av = ActionView::Base.new(ActionController::Base.view_paths, assigns)

      av.config = Rails.application.config.action_controller
      av.extend ApplicationController._helpers
      av.controller = ActionController::Base.new
      av.controller.request = ActionController::Request.new(request)
      av.controller.response = ActionController::Response.new
      av.controller.headers = Rack::Utils::HeaderHash.new

      av.class_eval do
        include Rails.application.routes.url_helpers
      end

      av.render options
    end
  end
end
{{< / highlight >}}

### Usage
{{< highlight ruby >}}
 html_output = RenderHelper.render({:instance_variable1 => "foo",
                                                :instance_variable2 => "bar"},
                                                :template => 'view_to/render')
{{< / highlight >}}

You can then use you're favorite PDF generator (I use PDFKit) to take the html output and parse it to a PDF.
