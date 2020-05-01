" This file defines all maktaba flags that will be used to configure the plugin.
" Users can configure these flags using |Glaive| or other plugins that hook into
" the maktaba#setting API. Maktaba will make sure this file is sourced
" immediately when the plugin is installed so that flags are defined and
" initialized to their default values before users configure them. See
" https://github.com/google/vim-maktaba/wiki/Creating-Vim-Plugins-with-Maktaba
" for details.

""
" @section Configuration, config
" @plugin(name) is configured using maktaba flags. It defines some flags that
" can be configured using |Glaive| or a plugin manager that uses the maktaba
" setting API. It also supports entirely disabling commands from being defined
" by clearing the plugin[commands] flag.
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

" TODO: Add documentation about how to set spcefic values in the cache, even
" though it is not a flag. This is part of the connfiguration that the user can
" change, but it is not a regular flag.
