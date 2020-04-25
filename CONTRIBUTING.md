> Currently, as long as the plugin doesn't have a stable version, contributions
> might not be expected. Before adding code, please start by contacting me
> (through the various options in github).

# Opening new Issues

In case you have found a problem in the plugin, or have a suggestion for new
feature for the plugin, you are more than welcome to open an issue in github.

In this case, make sure to document the issue enough so everyone else will
understand the issue. In case the issue is a bug report, it is best to explain
how to reproduce this bug. In case it is an enhancement, you should describe
what is the new functionality you want from the plugin.

In case you want to be assigned to the issue, write it, I will assign it to you.

# Contributing

If you want to contribute to the plugin, please do.
I welcome new ideas and would love to add more features to this plugin.

If you have an idea but you don't know how to implement it, you are more than
welcome to open an issue with it. If you have a small feature that you want to
implement, you are welcome to write it and open a pull request.
If you want to add a major feature, it is recommended to open an issue first, to
validate with me that this feature is indeed reasonable for this plugin.

If you want to solve one of the open issues of the plugin, talk to me (by
commenting on the relevant issues), I will assign you to the relevant issue.

# Coding Guidelines

When adding code to this plugin, please follow those simple rules when writing
the code:

* Write good commit messages. An explanation of good commit message as I see it
    can be found [here](https://commit.style/) or
    [here](https://chris.beams.io/posts/git-commit/).
* Follow the code conventions. There are some conventions that the code follows,
    keep following them as best as you can. Most of the conventions can be
    understood from reading the code, but some basic guidelines:
    * Wrap your lines at around 80 characters.
    * Add {{{ and }}} around every function in your code, making it collapsible
      using vim's marker option. Add the name of the function in both the
      opening and the closing parenthesis.
      * Add those markers to big parts of files if you add more then mere
        functions.
    * Document your function using vimdoc style.
* In case you change the interface of the plugin, be sure to add explanation
    about it in the [readme](README.md).

