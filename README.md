# vim-mr-interface
<!-- vim-markdown-toc GFM -->

* [Introduction](#introduction)
* [Usage](#usage)
    * [Commands](#commands)
        * [Gitlab Commands](#gitlab-commands)
        * [Cache Commands](#cache-commands)
    * [Configuration Options](#configuration-options)
* [Installation](#installation)
    * [Vundle](#vundle)
    * [Dependencies](#dependencies)
    * [Supported platforms](#supported-platforms)
* [Gitlab API Notes](#gitlab-api-notes)
    * [Discussion threads on code interface](#discussion-threads-on-code-interface)
    * [How to add new code discussion thread](#how-to-add-new-code-discussion-thread)
    * [Generating Tokens](#generating-tokens)
    * [Getting project id](#getting-project-id)
* [Common problems](#common-problems)
    * [Comments doesn't appear on changes](#comments-doesnt-appear-on-changes)
    * [It is impossible to add comments on unmodified files](#it-is-impossible-to-add-comments-on-unmodified-files)
    * [Adding comments on multiple lines of code](#adding-comments-on-multiple-lines-of-code)
* [More recommended tools](#more-recommended-tools)
* [FAQ](#faq)
    * [How should I solve the MR](#how-should-i-solve-the-mr)
    * [Why isn't this plugin developed in gitlab](#why-isnt-this-plugin-developed-in-gitlab)
    * [Will this plugin ever support PRs in github as well](#will-this-plugin-ever-support-prs-in-github-as-well)
* [Contributing](#contributing)
* [Roadmap](#roadmap)
    * [Release v0.1](#release-v01)
    * [Release v0.2](#release-v02)
    * [Release v1.0](#release-v10)
    * [Future Releases](#future-releases)

<!-- vim-markdown-toc -->

vim plugin that support doing CRs and MRs in gitlab

## Introduction
Writing code require doing code reviews (CRs) on this code. Since you are
writing the code in vim, why not do the CR inside vim as well?

The aim of this plugin is to let you do CR on code in gitlab from vim. CR
usually include opening a merge request (MR), and then moving over the diff in
the code and adding comments into the gitlab's MR. Since you are reading about
vim plugins, you probably know and understand why vim is a good tool for writing
and reading code. Why won't you want to do your CR in vim as well?
This plugin let you do the CR from vim, adding comments and discussion threads
wherever you want and updating all this information on the gitlab's MR.

The plugin does all this by using gitlab's API, which let you get, add, change
or delete comments from MRs in it (with a lot of other stuff that this plugin
doesn't touch).

## Usage

This plugin lets you review the code and add comments directly into an open MR.

In order to use it, you should have an open MR in gitlab. Add your comments from
vim using the various [commands](#commands) of the plugin, instead of by opening
gitlab's web.

### Commands

#### Gitlab Commands

* MRInterfaceAddComment - Add a comment into the MR.
* MRInterfaceAddGeneralDiscussionThread - Add a general discussion thread into
    the MR. A general discussion thread is the same as a comment, but it can be
    resolved.
* MRInterfaceAddCodeDiscussionThread - Add a discussion thread on specific
    location for the MR. This location currently can be only a line of text in
    one of the changed files (which is enough for almost anything).

#### Cache Commands

The plugin has some commands that can control the internal cache it keeps. This
cache will make you type the common values for the MR just once for every merge
request. You can read in the help file more about this cache mechanism.

The commands are:
* MRInterfaceResetCache - Reset the cache.
* MRInterfaceSetCache - Set all the values in the cache. You will be prompted to
    insert the values for the different keys one by one.
* MRInterfaceUpdateValueInCache - Set a specific value in the cache.

### Configuration Options

These flags can be configured for the plugin.
These flags should be configured using
[Glaive](https://github.com/google/vim-glaive).

* gitlab_server_address - The address of the gitlab server to use (in case you
    are not using gitlab.com).
* gitlab_private_token - Your private token to authenticate with gitlab.
* automatically_insert_cache - Should the cache be inserted authomatically, or
    should it be only the default.

## Installation

This plugin is written in pure vimscript, but it require some other plugins and
system commands in the system.

The plugin can be installed using any method of plugin installation for vim as
long as all the [Dependencies](#dependencies) will be present when the plugin is
loaded and run.

### [Vundle](https://github.com/VundleVim/Vundle.vim)

An example of how to install this plugin using Vundle:
``` vimscript
Plugin 'google/vim-maktaba'
Plugin 'google/vim-glaive'
Plugin 'LucHermitte/lh-vim-lib'
Plugin 'omrisarig13/vim-mr-interface'
```

### Dependencies

- [Curl](https://curl.haxx.se) - command line tool and library for transferring
  data with URLs
- [google/vim-maktaba](https://github.com/google/vim-maktaba/) - A vimscript
    plugin library. Used internally by the plugin.
- [google/vim-glaive](https://github.com/google/vim-glaive) - utility for
    configuring maktaba plugins. It is used to set the different configurable
    variables in the plugin.
- [LucHermitte/lh-vim-lib](https://github.com/LucHermitte/lh-vim-lib) - Library
    of Vim functions.

### Supported platforms

This plugin should work on any platform that can run the CURL from within
vim. However, it was tested only on Linux, so it is not guaranteed to work the
same under other systems.

## Gitlab API Notes

The plugin uses gitlab's API. Good information about it can be found in the docs
pages in Gitlab. Useful pages are:
* [Merge requests](https://docs.gitlab.com/ee/api/merge_requests.html)
* [Merge request
    discussions](https://docs.gitlab.com/ee/api/discussions.html#merge-requests)

Here is some more information about the interface that might be a bit harder to
find in their site:
### Discussion threads on code interface

The interface of adding new discussion threads on code is weird, and act in
unexpected ways (for example, when should the value of `old line` be present).

It seems that this is currently a problem in gitlab itself. I documented some of
the usage in [this section](#how-to-add-new-code-discussion-thread).

You can read some open issues in gitlab about this here:
* [35935](https://gitlab.com/gitlab-org/gitlab/-/issues/35935)
* [37518](https://gitlab.com/gitlab-org/gitlab/-/issues/37518)
* [36378](https://gitlab.com/gitlab-org/gitlab/-/issues/36378)
* [24328](https://gitlab.com/gitlab-org/gitlab/-/issues/24328)

(In case one of these issues are closed, this plugin might not be updated, and
please report it to me in case you notice it.)

### How to add new code discussion thread

The needed information when adding a new discussion thread on the code might be
counter intuitive sometimes.

This table includes some of the information for when to set what value in order
to add the wanted comment to the line you want to add it.

| Comment Type | Code On New Line | Code On Deleted Line | Modified Code (old part) | Modified Code (new part) | Unmodified code in changed file | Renamed File        |
|:------------:|:----------------:|:--------------------:|:------------------------:|:------------------------:|:-------------------------------:|:-------------------:|
| Old Path     | New File Name    | Deleted File Name    | File Name                | File Name                | File Name                       | Old File Name       |
| New Path     | New File Name    | Deleted File Name    | File Name                | File Name                | File Name                       | New File Name       |
| Old Line     | null             | Wanted Line          | Wanted Line              | null                     | Line in old code                | As described before |
| New Line     | Wanted Line      | null                 | null                     | Wanted Line              | Line in new code                | As described before |

### Generating Tokens

This plugin uses gitlab private token when it authenticate with gitlab. In order
you use this plugin, you will need to have a private token that can access
gitlab's API.

More information about private tokens (how to generate them, for example), can
be found [here](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html).

### Getting project id

In order to add comments into an MR, you need to know the ID of your
project. The ID of the project is a unique identifier that gitlab gave your
project when it was created.

The project ID is written in gitlab, in the `Details` section of your project,
right under the name of the project.

## Common problems

### Comments doesn't appear on changes

In order to make the comment appear as change, you must specify the full sha of
all the commits connected to it (base, head and start). If you don't specify the
full hash, it will seem to work, however, the comment won't appear on the
changes screen.

### It is impossible to add comments on unmodified files

It seems that there isn't any way to do it with the current API of gitlab.

There are a couple of issues on it in gitlab:
* [24636](https://gitlab.com/gitlab-org/gitlab/-/issues/24636)
* [24328](https://gitlab.com/gitlab-org/gitlab/-/issues/24328)

(In case one of these issues are closed, this plugin might not be updated, and
please report it to me in case you notice it.)

### Adding comments on multiple lines of code

It seems that this doesn't currently work as well.

The relevant issue on gitlab is here:
* [14128](https://gitlab.com/gitlab-org/gitlab/-/issues/14128)

(In case one of these issues are closed, this plugin might not be updated, and
please report it to me in case you notice it.)

## More recommended tools

This plugin aims to help you do CRs in vim. There are some more tools that can
help you do MRs in your computer:

* [git-extras](https://github.com/tj/git-extras) - A library that adds more git
    command. The command that can help solves MRs is `git mr`. More information
    can be found in the man page of this command.
* [fugitive](https://github.com/tpope/vim-fugitive) - This great vim plugin let
    you run a lot of git commands from vim. A great command that can help solve
    MRs is `Gdiff` with all its different styles (`Gvdiff` and `Gsdiff`). This
    command will let you look about the diff between two git revisions, which
    can be extremely useful for looking at diff between the target and the
    source branches of an MR.

## FAQ

### How should I solve the MR

Sadly, currently this plugin doesn't support any options to solve the MR. It is
planned for the future, and if you want to help, you are more than welcome.

### Why isn't this plugin developed in gitlab

I already had a user with git plugin in github, and I wanted all the plugins to
be in the same place. It might move over to gitlab as well in some point in time
the future.

### Will this plugin ever support PRs in github as well

Right now, it is not planned to. However, if it will turn to be easy and
possible, the plugin might support these options in the future.

## Contributing

If you want to contribute anything to this plugin, first of all, thank you.

Secondly, please read [CONTRIBUTING.md](CONTRIBUTING.md).

## Roadmap

This is the general road-map of the Plugin implementation. Issues might be
release in versions prior to their planned release, but they should not be
released in versions later than the planned one (except for special cases).

### Release v0.1
- [x] Add roadmap ([#1][i1])
- [x] Add contributing guidelines ([#12][i12])
- [x] Add comments ([#2][i2])
- [x] Add general discussion threads ([#3][i3])
- [x] Add code discussion threads ([#4][i4])
- [x] Add Plugin default parameters ([#14][i14])
- [x] Create Plugin documentation ([#5][i5])
- [x] Release v0.1 ([#6][i6])

### Release v0.2
- [x] Change comments to use temporary buffers ([#7][i7])
- [x] Print errors for bad requests ([#29][i29])
- [ ] Add option to create comment on current line ([#8][i8])
- [ ] Add parameter calculation to the plugin ([#9][i9])
- [ ] Release v0.2 ([#16][i16])

### Release v1.0
- [ ] Add code discussions using fugitive ([#10][i10])
- [ ] Release v1.0 ([#17][i17])

### Future Releases
- [ ] Change authentication to be more secured ([#11][i11])
- [ ] Get comments from gitlab ([#13][i13])
- [ ] Add comments on the code ([#15][i15])

[i1]: https://github.com/omrisarig13/vim-mr-interface/issues/1
[i2]: https://github.com/omrisarig13/vim-mr-interface/issues/2
[i3]: https://github.com/omrisarig13/vim-mr-interface/issues/3
[i4]: https://github.com/omrisarig13/vim-mr-interface/issues/4
[i5]: https://github.com/omrisarig13/vim-mr-interface/issues/5
[i6]: https://github.com/omrisarig13/vim-mr-interface/issues/6
[i7]: https://github.com/omrisarig13/vim-mr-interface/issues/7
[i8]: https://github.com/omrisarig13/vim-mr-interface/issues/8
[i9]: https://github.com/omrisarig13/vim-mr-interface/issues/9
[i10]: https://github.com/omrisarig13/vim-mr-interface/issues/10
[i11]: https://github.com/omrisarig13/vim-mr-interface/issues/11
[i12]: https://github.com/omrisarig13/vim-mr-interface/issues/12
[i13]: https://github.com/omrisarig13/vim-mr-interface/issues/13
[i14]: https://github.com/omrisarig13/vim-mr-interface/issues/14
[i15]: https://github.com/omrisarig13/vim-mr-interface/issues/15
[i16]: https://github.com/omrisarig13/vim-mr-interface/issues/16
[i17]: https://github.com/omrisarig13/vim-mr-interface/issues/17
[i29]: https://github.com/omrisarig13/vim-mr-interface/issues/29
