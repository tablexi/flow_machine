# FlowMachine

Build finite state machines in a backend-agnostic, class-centric way.

The basic features will work with any PORO, and more features and callbacks are available when used with an ORM like `ActiveRecord` and/or `ActiveModel::Dirty`.

 _Circle CI Status:_ [![Circle CI](https://circleci.com/gh/tablexi/flow_machine.svg?style=svg)](https://circleci.com/gh/tablexi/flow_machine)
## *Raison d'être*

After exploring several of the existing Ruby state machine options, they all seem too tightly coupled to an ORM models and tend to pollute the object model's code far too much. The goal of this gem is to provide a clean, testable interface for working with a state machine that decouples as much as possible from the model object itself.

## Upgrading

[CHANGELOG.md](CHANGELOG.md) will contain changes that need to be made at each version

## Requirements

Ruby 2.0+

## Simple Usage

```ruby
class BlogPost
  attr_accessor :state, :title, :body, :author

  def initialize
    self.state = :draft
  end
end

class PublishingWorkflow
  include FlowMachine::Workflow

  state DraftState
  state PublishedState
end

class DraftState < FlowMachine::WorkflowState
  event :publish do
    transition to: :published
  end
end

class PublishedState < FlowMachine::WorkflowState
  on_enter :notify_email_author
  on_exit :clear_published_at

  def notify_email_author
    # Send an email
  end

  def clear_published_at
    object.published_at = nil
  end
end
```

```ruby
blog_post = BlogPost.new
blog_post.author = "author@example.org"
workflow = PublishingWorkflow.new(blog_post)
workflow.publish # notify_email_author is called (returns true if successful)
workflow.published? # => true
blog_post.state # => :published
```


## `transition!`

If you are using the workflow around an ORM model like ActiveRecord, calling the bang version of the transition will perform the transition and call `save` on the object. This method will return the value returned by `save` (`true`/`false` for ActiveRecord) or `false` if any of the guards fail.

E.g. `workflow.publish!` will transition the object to `published` and call `save` on the object.

## Guards

Guards are used to allow or prevent `event`s from being called. `:guard` accepts a single symbol or an array of symbols representing methods. The method may be on the state, the workflow, or the object itself, and the method will be searched for in that order.

**Best practice** Use predicate methods that return a simple true/false. All guard methods are called, so avoid side affects in these methods.

Calling the transition with a failing guard will result in the object not being transitioned and returning `false`. If using the bang version, `save` will not be called.

#### may_xxx?

`workflow.may_publish?` will call all the guard methods and return `false` if any of the guard methods return `false`. It will also return `false` if you are not in a state that has a defined event (e.g. `published_workflow.may_publish?` will always return `false`)

#### guard_errors

After calling `may_xxx?`, the workflow will have an array of the guard methods that failed. To avoid additional dependencies, the developer is responsible for converting these to human readable messages (using I18n or the like). This may include `:invalid_event` in the case where a transition from the current state is not defined.

```ruby
class DraftState < FlowMachine::WorkflowState
  event :publish, guard: [:content_present?, :can_publish?]
    transition to: :published
  end

  def can_publish?
    false
  end
end

class BlogPost
  def content_present?
    content.present? # assuming you have ActiveSupport loaded
  end
end
```

```ruby
workflow.may_publish? # => false
workfow.guard_errors # => [:can_publish?]
workflow.publish # => false
```

## Callbacks

State and Workflow callbacks accept `if` and `unless` options. They may be a symbol or array of symbols (looking for the method in the state, workflow, and object in that order) or a Proc.

### State callbacks

Declared in the `WorkflowState` class.

* `on_exit` Called after the object has transitioned out of the state.
* `on_enter` Called after the object has transitioned into the state. Triggered after the previous state's `on_exit`.

The following are available when `Workflow#save` is used (`workflow.save` or `workflow.transition!`) *Not called if you call `save` directly on the decorated model*.

* `after_enter` Called when the object has transitioned into the state and the object has been saved either `workflow.save` or `workflow.transition!` has been called.
* `before_change` Useful when watching for changes to a model, but only when in a certain state. Will be called if anything exists in the `object#changes` hash (if it exists), often provided by `ActiveModel#dirty`.
* `after_change` Useful when watching for changes to a model in a certain state, but you only want to trigger when the save is successful (e.g. the model is `valid?`)

### Workflow callbacks

Declared in the `Workflow` class.

* `after_transition` Called anytime a transition takes place

The following are available when `Workflow#save` is used:

* `before_save` Called when `Workflow#save` is called, but before `object#save` is called
* `after_save` Called after `object#save` has returned `true`

### Transition callbacks

Declared as an option to the `transition` method inside an `event` block.

* `after` Will be called after the transition has happened successfully including persistance (if applicable). Useful when you only want something to trigger when moving from a specific state to another.

`transition to: :published, after: :send_mailing_list_email`

## FlowMachine::Workflow.for

You can easily access the workflow for your particular object, class, or collection of objects.

Examples:

```ruby
blog = BlogPost.new
FlowMachine::Workflow.for(blog) # => BlogPostWorkflow

FlowMachine::Workflow.for(BlogPost) # => BlogPostWorkflow
```

You can also create an collection of workflow objects via:

```ruby
blog_posts = BlogPost.all

FlowMachine::Workflow.collection_for(blog_posts) # => [BlogPostWorkfow.new(blog_post[0]), ..., BlogPostWorkflow.new(blog_post[n])
```


## Scopes and Predicate methods

If you want scopes and predicate methods defined on your model, use the following:

`PublishingWorkflow.create_scopes_on(self)` within the model.

Assuming BlogPost is an ActiveRecord model, this will create `BlogPost.draft` and `BlogPost.published` scopes as well as the `BlogPost#draft?` and `BlogPost#published?` methods.

## Other useful features

### Use a different attribute for the state

If you don't want to use `state` as your field for storing state, simply declare `state_attribute :status` in the Workflow class.

### List of state names

```ruby
PublishingWorkflow.state_names` # => ['draft', 'published']
```

Especially useful in an ActiveModel validation:

```ruby
validates :state, presence: true, inclusion: { in: PublishingWorkflow.state_names }
```

### Options Hash

You can pass an options hash into the workflow which is available at any time while using the workflow. A prime example is tracking the user who performed an action.

```ruby
class PublishedState < FlowMachine::WorkflowState
  on_enter :update_published_by

  def update_published_by
    object.published_by = options[:current_user]
  end
end

workflow = PublishingWorkflow.new(blog_post, current_user: User.find(123))
workflow.publish
blog_post.published_by # => User #123
```
