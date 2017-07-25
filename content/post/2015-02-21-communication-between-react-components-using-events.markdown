---
categories: null
comments: true
date: 2015-02-21T10:20:39Z
title: Communication between React components using events
url: /2015/02/communication-between-react-components-using-events/
---

Here is an example of a clean way to communicate between React components without getting stuck passing `@prop` callbacks all around. Inspired by looking at the new Flux React utilities.

We're going to start off with a simple HAML file:

{{< highlight haml >}}
%script{src: "https://cdnjs.cloudflare.com/ajax/libs/react/0.12.2/react-with-addons.js"}
%div{data: { ui: 'alerts' }}
%div{data: { ui: 'widgets' }}
:javascript
  React.renderComponent(Widgets(), document.querySelector('[data-ui="widgets"]'))
  React.renderComponent(Alerts(), document.querySelector('[data-ui="alerts"]'))
{{< / highlight >}}

Next comes our `Widget` component.

{{< highlight coffeescript >}}
{div, button} = React.DOM

Widgets = React.createClass
	render: ->
    div className: 'widget',
    	button className: 'btn btn-primary', onClick: (=> @_sendMsg('Testing')), 'Click Me'
	_sendMsg: (msg) ->
    $('[data-ui="alerts"]').trigger("message", ["Widget clicked."])
{{< / highlight >}}

On line 1 we're defining some easy helper methods to access the `React.DOM` object - otherwise on every line we'd be writing something like `React.DOM.div` or whichever element we were going to call.

Line 4 is our render method. Everytime state gets mutated or the component is loaded, this method is called.

On line 6 we're creating an anonymous function but passing in the local scope using a fat arrow `=>` so we can access our other functions in the class. We call it inside an anonymous function so we can pass an argument to it, in this case the message.

Line 7 is our function that fires the event. I'm using the `_sendMsg` syntax to denote it is a private function. The first argument to the jQuery event emitter is the event name, followed by a list of arguments.

Now lets write our `Alert` handler and go through it line by line.

{{< highlight coffeescript >}}
{div} = React.DOM
Alerts = React.createClass
  messageTimeout: 5000
  getInitialState: ->
    messages: []

  componentDidMount: ->
    $('[data-ui="alerts"]').on 'message', (event, msg) =>
      msgs = @state.messages
      msgs.push(msg)
      @setState(messages: msgs)

  componentDidUpdate: ->
    @state.messages.map (msg, index) =>
      setTimeout(( => @_removeMsg(index)), @messageTimeout)

  render: ->
    div {},
      @state.messages.map (msg, index) =>
        div className: 'alert alert-info',
          msg

  _removeMsg: (index) ->
    msgs = @state.messages
    msgs.splice(index, 1)
    @setState(messages: msgs)
{{< / highlight >}}

Line 1 we're doing the same thing as before, creating a little helper method.

Line 3 is a class variable (we also could have used `props` here but I went with the class variable instead).

Line 4 is a function that defines the initial state of the component once it is mounted on the page. Here we are saying that there is an empty `messages` array.

Line 7 is a life cycle event of a React component, called `componentDidMount` which is called after the component has been rendered into the DOM and mounted.
Here we are telling jQuery to bind to any events that are triggered on the `[data-ui="alerts"]` object and process them. We take the current messages from `@state.messages`, `push` the newest message on to the end and then finally call `@setState` to mutate the components state.

Now the next part on line 13 is how we can gracefully remove messages after they have been rendered. `componentDidUpdate` is another React life cycle event and is called after a render occurs (and renders occur because the component was updated).
We iterate over each message using the `map` function and call `setTimeout` with an anonymous function that calls `@_removeMsg` and passes in an index. `@messageTimeout` is how we access the class variable defined at the top of the file.

Line 17 is a `render` call to display all the messages. Note that it is wrapped in a div because you can't return a collection of objects from render, it must a single root element with nodes underneath.

Line 23 is our message removal function. We set `@state.messages` to a local variable, remove one element at `index` and then mutate the state by setting it to our local variable with `@setState`.

Below is an example of the final product.




<p data-height="343" data-theme-id="0" data-slug-hash="ZYoEWg" data-default-tab="result" data-user="joshrendek" class='codepen'>See the Pen <a href='http://codepen.io/joshrendek/pen/ZYoEWg/'>ZYoEWg</a> by Josh Rendek (<a href='http://codepen.io/joshrendek'>@joshrendek</a>) on <a href='http://codepen.io'>CodePen</a>.</p>
<script async src="//assets.codepen.io/assets/embed/ei.js"></script>


I'd like to thank my friend/co-worker <a href="http://robertwpearce.com/blog/">Robert Pearce</a> for getting me into React and showing me that everything doesn't need to be jQuery!
