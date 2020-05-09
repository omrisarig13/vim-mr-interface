" This file defines all maktaba flags that will be used to configure the plugin.
" Users can configure these flags using |Glaive| or other plugins that hook into
" the maktaba#setting API. Maktaba will make sure this file is sourced
" immediately when the plugin is installed so that flags are defined and
" initialized to their default values before users configure them. See
" https://github.com/google/vim-maktaba/wiki/Creating-Vim-Plugins-with-Maktaba
" for details.

""
" @section Introduction, intro
" @order intro config commands cache
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
" The values that the plugin can calculate by itself are:
"   * merge request id - from the current branch name.
call s:plugin.Flag('automatically_insert_defaults', v:true)

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
" @section Adding Comments On Unchanged Code, comments-on-unchanged-code
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
