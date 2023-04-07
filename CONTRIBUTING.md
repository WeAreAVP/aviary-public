# How to Contribute

We want your help to make AVIARY great. There are a few guidelines
that we need contributors to follow so that we can have a chance of
keeping on top of things.

## Intellectual Property Licensing and Ownership

All code contributors must have an Individual Contributor License Agreement
(iCLA) on file with the Audio Visual Preservation Solutions, Inc. If the contributor works for
an institution, the institution must have a Corporate Contributor License
Agreement (cCLA) on file.

[Corporate Contributor License Agreement](https://coda.aviaryplatform.com/intellectual-property-licensing-59#_luNNJ)

[Individual Contributor License Agreement](https://coda.aviaryplatform.com/intellectual-property-licensing-59#_luENY)

## Contribution Tasks

* Reporting Issues
* Making Changes
* Documenting Code
* Committing Changes
* Submitting Changes

### Reporting Issues

* Make sure you have a [GitHub account](https://github.com/signup/free)

* Submit a [Github issue](./issues) by:
  * Clearly describing the issue
    * Provide a descriptive summary
    * Explain the expected behavior
    * Explain the actual behavior
    * Provide steps to reproduce the actual behavior

### Making Changes

* Fork the repository on GitHub

* Create a topic branch from where you want to base your work.
  * This is usually the master branch.
  * To quickly create a topic branch based on master; `git branch fix/master/my_contribution master`
  * Then checkout the new branch with `git checkout fix/master/my_contribution`.
  * Please avoid working directly on the `master` branch.
  * You may find the [hub suite of commands](https://github.com/defunkt/hub) helpful

* Make sure you have added sufficient tests and documentation for your changes.
  * Test functionality with RSpec; Test features / UI with Capybara.

* Run _all_ the tests to assure nothing else was accidentally broken.

### Documenting Code

* All new public methods, modules, and classes should include inline documentation in [YARD](http://yardoc.org/).
  * Documentation should seek to answer the question "why does this code exist?"

* Document private / protected methods as desired.

* If you are working in a file with no prior documentation, do try to document as you gain understanding of the code.
  * If you don't know exactly what a bit of code does, it is extra likely that it needs to be documented. Take a stab at it and ask for feedback in your pull request. You can use the 'blame' button on GitHub to identify the original developer of the code and @mention them in your comment.
  * This work greatly increases the usability of the code base and supports the on-ramping of new committers.
  * We will all be understanding of one another's time constraints in this area.

* YARD examples:

  * [Getting started with YARD](http://www.rubydoc.info/gems/yard/file/docs/GettingStarted.md)

### Committing changes

* Make commits of logical units.

  * Your commit should include a high level description of your work in HISTORY.textile

* Check for unnecessary whitespace with ```git diff --check``` before committing.

* Make sure your commit messages are [well formed](http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html).

* If you created an issue, you can close it by including "Closes #issue" in your commit message. See [Github's blog post for more details](https://github.com/blog/1386-closing-issues-via-commit-messages)

```detail
    Present tense short summary (50 characters or less)

    More detailed description, if necessary. It should be wrapped to 72
    characters. Try to be as descriptive as you can, even if you think that
    the commit content is obvious, it may not be obvious to others. You
    should add such description also if it's already present in bug tracker,
    it should not be necessary to visit a webpage to check the history.

    Include Closes #<issue-number> when relavent.

    Description can have multiple paragraphs and you can use code examples
    inside, just indent it with 4 spaces:

        class PostsController
          def index
            respond_to do |wants|
              wants.html { render 'index' }
            end
          end
        end

    You can also add bullet points:

    - you can use dashes or asterisks

    - also, try to indent next line of a point for readability, if it's too
      long to fit in 72 characters
```

* Make sure you have added the necessary tests for your changes.
* Run _all_ the tests to assure nothing else was accidentally broken.
* When you are ready to submit a pull request

### Submitting Changes

[Detailed Walkthrough of One Pull Request per Commit](http://ndlib.github.io/practices/one-commit-per-pull-request/)

* Read the article ["Using Pull Requests"](https://help.github.com/articles/using-pull-requests) on GitHub.

* Make sure your branch is up to date with its parent branch (i.e. master)
  * `git checkout master`
  * `git pull --rebase`
  * `git checkout <your-branch>`
  * `git rebase master`
  * It is a good idea to run your tests again.
  

* If you've made more than one commit take a moment to consider whether squashing commits together would help improve their logical grouping.
  * [Detailed Walkthrough of One Pull Request per Commit](http://ndlib.github.io/practices/one-commit-per-pull-request/)
  * `git rebase --interactive master` ([See Github help](https://help.github.com/articles/interactive-rebase))
  * Squashing your branch's changes into one commit is "good form" and helps the person merging your request to see everything that is going on.

* Push your changes to a topic branch in your fork of the repository.

* Submit a pull request from your fork to the project.

## Additional Resources

* [General GitHub documentation](http://help.github.com/)
* [GitHub pull request documentation](https://help.github.com/articles/about-pull-requests/)
* [Pro Git](http://git-scm.com/book) is both a free and excellent book about Git.
* [A Git Config for Contributing](http://ndlib.github.io/practices/my-typical-per-project-git-config/)
