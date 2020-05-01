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
" @section Cache Flags, cache_flags
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
" the instructions from here: @section(cache_flags)
