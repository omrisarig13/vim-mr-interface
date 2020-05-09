" This file defines all maktaba flags that will be used to configure the plugin.
" Users can configure these flags using |Glaive| or other plugins that hook into
" the maktaba#setting API. Maktaba will make sure this file is sourced
" immediately when the plugin is installed so that flags are defined and
" initialized to their default values before users configure them. See
" https://github.com/google/vim-maktaba/wiki/Creating-Vim-Plugins-with-Maktaba
" for details.

""
" @section Introduction, intro
" @order intro config commands cache default-values
" This plugin is a plugin that will let you write CRs on gitlab MRs directly
" from vim.
"
" The plugin introduces some commands that can be used to send comments directly
" from your vim into an MR in gitlab, and have a cache mechanism that will save
" your information and let you send lots of commands one after the other without
" setting these variables over and over again.

""
" @section Configuration, config
" @plugin(name) is configured using maktaba flags. It defines some flags that
" can be configured using |Glaive| or any other plugin manager that uses the
" maktaba setting API. It also supports entirely disabling commands from being
" defined by clearing the plugin[commands] flag.
"
" Basic example of setting a |Glaive| flag is:
"
"   Glaive vim-mr-interface gitlab_private_token="12345678910111213141"
"
" For full information about how to configure the flags, you can read Glaive
" documentation: https://github.com/google/vim-glaive/blob/master/README.md.

" Header guard to make sure that this file is source only once.
let [s:plugin, s:enter] = maktaba#plugin#Enter(expand('<sfile>:p'))
if !s:enter
  finish
endif

""
" Save the address of the gitlab server to run the commands on.
call s:plugin.Flag('gitlab_server_address', 'gitlab.com')

""
" Save the private token to use when authenticating with gitlab.
" This flag should be defined by the user with the proper gitlab authentication
" information. If it will stay empty, the user will be prompt to add the private
" token every time he runs any command.
call s:plugin.Flag('gitlab_private_token', '')

""
" Save whether the plugin should use the cache value instantly, or always ask
" the user to insert the needed values.
call s:plugin.Flag('automatically_insert_cache', v:true)

""
" Save whether the plugin should use the default values it calculates by itself
" instantly, or always ask the user to insert the needed values.
"
" For more information about default values, see @section(default-values).
call s:plugin.Flag('automatically_insert_defaults', v:true)

""
" Whenever the plugin need to get data, it has three methods to do so:
"   * Get the data from the cache.
"   * Get the data from default the plugins calculates.
"   * Get the data directly from the user.
" This flag control the order in which the plugin will try to get the data. In
" case the value of this flag will be true, the plugin will start by searching
" for the value in the cache, and only if it is not in the cache, it will use
" the default.
" In case the flag will be false, the plugin will start by looking for the value
" in the defaults, and only if it can't get it from there, it will get the value
" from the cache.
"
" It is recommended to start the search in the cache, because it should be faster
" for some values (when the getting of the default value require communication
" with gitlab for example).
"
" For more information about default values, see @section(default-values).
call s:plugin.Flag('use_cache_before_defaults', v:true)

""
" Save whether the plugin should create a buffer whenever it needs to read the
" body of a message from the user, or get the body in the regular method.
"
" For more information about reading the body from a buffer, read
" @section(inserting-body).
call s:plugin.Flag('read_body_from_buffer', v:true)

""
" The height of the scratch buffer that will be created when inserting the body.
"
" This is relevant only in case the value of @flag(read_body_from_buffer).
call s:plugin.Flag('body_buffer_height', 5)

""
" Whether to support fugitive file names.
"
" When editing the code using fugitive, with the command of Gdiffsplit (and
" Gsdiffsplit, Ghdiffsplit) the names of the old files are being changed.
" In case this flag will be true, whenever the plugin will get the file name, it
" will turn files from fugitive names into regular names, so they will be able
" to be added to the gitlab as comments.
call s:plugin.Flag('support_fugitive_file_names', v:true)

""
" A dictionary that maps between a project to its ID.
"
" This dictionary can be used to make the plugin understand automatically the id
" of the project from the name of its directory.
" This dictionary is case sensitive.
call s:plugin.Flag('names_to_id', {})

""
" Whether to parse or not parse the references that the plugin gets.
"
" For more information, read @setction(sha-values).
call s:plugin.Flag('should_parse_references', v:true)

""
" @section Cache Flags, cache-flags
" @parentsection config
" The values of the cache flags can be also used when configuring the
" plugin. However, you probably don't want that.
"
" In case you do want to configure the cache values, you can call
" @command(MRInterfaceUpdateValueInCache) from anyplace in your vimrc.
"
" This way, you will be able to set the values of the cache in load time of vim,
" exactly as you would have done for any other configuration flags. The possible
" values of the configuration flags are:
"   * 'base sha'
"   * 'start sha'
"   * 'head sha'
"   * 'project id'
"   * 'merge request id'
"   * 'gitlab private token'
"
" For example:
"
"   MRInterfaceUpdateValueInCache 'merge request id' 4
"
" For more information about the cache mechanism, see @section(cache).

""
" @section Cache, cache
"
" Whenever working on a gitlab MR, a lot of the parameters for many functions
" will stay the same for a sequence of commands.
"
" For example, whenever working on a single MR, all these arguments will stay
" the same across all the calls:
" * The id of the merge request
" * The id of the project
" * The sha of the base commit in the MR
" * The sha of the head commit in the MR
" * The sha of the start commit in the MR
"
" Because all these arguments will stay the same, this plugin creates a cache
" mechanism that will save these arguments and set them for you.
"
" Whenever you will run one of the interactive commands for the first time, it
" will prompt you to insert all the arguments that it needs. This should be the
" only time that you inserts the constant arguments for this vim session. From
" now on, every command that will run will use the arguments that you have
" inserted originally. This will include only the arguments that should stay the
" same for the merge request, letting you change the variable that changes
" between different comments on the code.
"
" By default, you won't be bothered again with these arguments, however, it is
" configurable and can be changed. To see how it can be changed, see
" @flag(automatically_insert_cache). If this flag will be false, the values from
" the cache won't be set automatically, but they will be the default values for
" their parameters, letting you not insert them (by setting empty value, or
" a value of `null`).
"
" In case you had made a mistake, or want to update a single argument in the
" cache, you can use the command of @command(MRInterfaceUpdateValueInCache).
"
" In case you want to reset the cache completely, use
" @command(MRInterfaceResetCache).
"
" And, in case you don't want to set the cache with a command, but just set all
" its values upfront, you can use the command of @command(MRInterfaceSetCache)
"
" The whole cache is per vim session. It means that once you have exited your
" vim session, the cache will be deleted, and there wouldn't be any way to
" retrieve it.
"
"
" Why use cache and not global variables?
"
" All the arguments that are part of the cache are arguments that will be the
" same across some sequental calls to the various plugin's functions, but won't
" be the same across different vim sessions. For example, the MR number will
" stay the same as long as you work on the same gitlab MR, but once you have
" finished with it, you wouldn't use the same number again. Moreover, in case
" you work on more than one gitlab project at a time, you will need to have
" different values for the project's id during this time.
" From this reason, it is wrong to set these variables as globals (they change
" too often and can't be the same across all the vim's instances). The solution
" of cache will work best to help complete you and set the values for you,
" without continuing to use the old values when they no longer makes sense.
"
" In case you don't want to use the values as cache, you can just use them as
" regular global values by setting them explicitly in your vimrc according to
" the instructions from here: @section(cache-flags)


""
" @section Inserting Body, inserting-body
" @parentsection commands
" By default, whenever running a command that needs to get the body of any
" command sent to gitlab, the body of the command will be inserted from
" a temporary buffer.
"
" This is done because a lot of the time, the body of the command will be long,
" and might consist of several different sentences. Because the input consists
" of several sentences, it can't be inserted using the |input()| method (which
" get the input from the menu at the bottom of vim) because this command can not
" get more than one line. Moreover, whenever typing a lot of information, it is
" a lot easier to write it with full vim compatibility than to insert it as text
" in the command window.
"
" When the command will run in vim, a new unnamed buffer will be open at the top
" of the current tab. You should write the body of the comment into this
" buffer. When the buffer will be closed, the body will be taken from it (it
" does not matter if the buffer will be saved or not). After the buffer will be
" closed, it will be completely wiped out of vim's memory (to not clutter the
" memory with a lot of unused buffers).
"
" After running a command, but before filling the information inside the buffer,
" you can do whatever you want with vim (it is completely okay to move around,
" change windows, tabs, open or close any other files, copy information to and
" from this buffer...). However, it will be impossible to run any other command
" from this plugin until this buffer will be closed and the current command will
" be completed. In case you want to cancel the current command, you can leave
" the buffer empty, it will cancel the function.
"
" In case you don't want this functionality, and want to insert the body as all
" the other variables (using the |input()| method), you can change the value of
" @flag(read_body_from_buffer).

""
" @section Adding Comments On Unchanged Code, unchanged-code
" @parentsection commands
" During some CRs, there is a need to add comments on code that was not changed
" during the MR, but was affected by other changes in the code. It seems
" reasonable that there would be a command that will add such comment (like the
" commands of MRInterfaceAddCodeDiscussionThreadOnOldCode or
" MRInterfaceAddCodeDiscussionThreadOnNewCode). However, there isn't such
" command currently.
"
" The reason that there isn't such command is that adding command on unchanged
" code is hard with the current API interface of gitlab. As for now, when adding
" code on unchanged lines, there are two possible scenarios:
"   * Code on file that was not changed - As for now, it is impossible. Gitlab
"     doesn't allow users to add comments on files that weren't changed during
"     the merge request. I recommend creating a regular discussion thread for
"     this.
"   * Unchanged code in a file that has changes - It is possible. However, when
"     sending the comment to gitlab, the parameters should include both the line
"     number in the old code, and the line number in the new code. As for now,
"     it is impossible to do with the plugin in its own command, because the
"     plugin can't know what is the line number of the code in the other
"     revision (the line number can be different in case code was added or
"     deleted before the current line). Such comments can be added by running
"     the regular command (MRInterfaceAddGeneralDiscussionThread and writing
"     manually the line numbers for the new discussion thread).
"     It might be possible to support such comments in the future, when this
"     plugin will support fugitive integration.

""
" @section Defaults Values, default-values
"
" The plugin has an calculate values for some of the needed values, and use them
" as default values.
"
" This calculation is done using various git commands, using some global
" variables and using the gitlab API to get more information for the different
" variables.
"
" Any time the plugin will need to have a value for some variable in it, there
" is an option that the plugin will calculate this value by itself, and use this
" value as the default value.
"
" The default values will be used without asking the user about them. To
" customize it (make the plugin ask the user before adding the default value),
" see @flag(automatically_insert_defaults).
"
" The default values will be used only in case the values are not already in the
" cache. To customize it, see @flag(use_cache_before_defaults)
"
" These are the keys that can have default values, with explanation about how
" these default values are being calculated:

""
" @section Default Merge Request ID, default-mr-id
" @parentsection default-values
"
" When sending commands to gitlab, it needs to know to which merge request it
" should be added. Every merge request has a unique id that is being sent to the
" gitlab.
"
" The plugin can get the merge request automatically in case the user is working
" in a git repository on the branch of the merge request. Branches of a merge
" request are branches that their name is from the format "mr/<MR_id>".
"
" The user can do one of two things in order to be in such branch:
" * Get the merge request branch using `git mr`. This command is part of the
"   git-extras repository. It moves you to a new branch, with the name from the
"   given format, and on the head of this merge request. This is the recommended
"   method.
" * Create such branch. The user can also create a branch with this name. This
"   is worse than using the `git mr` command (because it is a lot more manually,
"   and won't update autmotically), however, it will work the same for the
"   plugin.

""
" @section Default Project ID, default-project-id
" @parentsection default-values
"
" When sending commands to gitlab, it needs to know the ID of the project it
" should add the comment into. Every project has a unique id that is being sent
" to the gitlab.
"
" It is hard for the plugin to get the ID of the project completely
" automatically (it might be supported in the future). For now, it can be done
" semi-automatically.
"
" The plugin will be able to understand by itself the name of the directory for
" the current project. The user should define the variable of @flag(names_to_id)
" to include the name of the project as a key, and the ID of the project as the
" value.
"
" That way, the plugin will be able to get the ID of all the projects that were
" defined that way automatically as long as the user is working on them.

""
" @section SHAs, sha-values
" @parentsection commands
"
" A lot of the command that are responsible on adding comments that are
" connected to the code needs SHAs of commits connected to them.
"
" Gitlab requires to get the full SHA of the commit in order to successfully add
" the comment and connect it to the code.
"
" The plugin doesn't need to get the full SHA of the commit in order to
" understand it, in case you are in the same repository.
"
" Whenever the plugin will need to send a SHA to gitlab, it will try to get the
" full sha using the command of `git rev-parse`, which mean that it will
" understand every git reference.
"
" It means that as long as you are in the same repository that you adds comments
" to, you can set any reference value that you want as the value of the SHA. It
" can be any one of the following (and probably some more):
"   * Partial SHA that points to a unique commit
"   * Full SHA of a commit
"   * Branch Name
"   * Tag Name
"   * HEAD
"   * Reference to other reference (HEAD~1, v1.0^, ffaabb~5...)
"
"
" In case you are not adding comments from the same repository (you are inside
" a different repository while you are adding the comments), there might be
" problems with this (in case you are referencing objects that exists (by
" accident) in both repositories).
"
" In this case, make sure to turn the flag of @flag(should_parse_references)
" off.
