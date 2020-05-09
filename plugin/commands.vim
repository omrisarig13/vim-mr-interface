" This file includes all the different commands of the plugin.

" File needed information {{{

""
" @section Commands, commands


" Header guard to make sure that this file is source only once.
let [s:plugin, s:enter] = maktaba#plugin#Enter(expand('<sfile>:p'))
if !s:enter
  finish
endif

" Not overrunning commands on purpose - this code is safe inside a header guard,
" so if there is any error with the command, it means that the user has already
" defined such command.

" File needed information }}}

" Commands {{{

" MRInterfaceAddComment {{{
""
" @usage
" Add a comment into a gitlab MR.
" If run without arguments, this function works interactively (asks you for all
" the needed arguments during the command run and add them as you insert them).
" Once all the arguments are inserted, the comment will be added to the gitlab
" MR.
" This command will get the body of the comment from a new buffer (by
" default). To read more about it, read @section(inserting-body).
"
" @usage [body]
" Add a comment into a gitlab MR. In this form, the body of the comment will be
" according to the parameter. All the other arguments must be present in the
" cache, and they will be used from there.
" In case there are missing arguments, an error will be printed to the screen.
" In order to fill the arguments in the cache, @command(MRInterfaceSetCache) can
" be used.
"
" @usage [body] [project_id] [merge_request_id]
" Add a comment to gitlab. In this form, the comment that will be added will
" have all the arguments as given from the ex-command.
"
" @usage [body] [private_token] [project_id] [merge_request_id]
" This is the same as the previous form except that in this form the
" [private_token] is inserted as well. When run with this form, the private
" token that will be inserted will be used, ignoring the global private token.
command -nargs=* MRInterfaceAddComment call mr_interface#AddComment(<f-args>)
" MRInterfaceAddComment }}}

" MRInterfaceAddGeneralDiscussionThread {{{
""
" @usage
" Add a general discussion thread into a gitlab MR.
" A general discussion thread is the same as comment, but it can be resolved.
" If run without arguments, this function works interactively (asks you for all
" the needed arguments during the command run and add them as you insert them).
" Once all the arguments are inserted, the new discussion thread will be added
" to the gitlab MR.
" This command will get the body of the comment from a new buffer (by
" default). To read more about it, read @section(inserting-body).
"
" @usage [body]
" Add a general discussion thread a gitlab MR. In this form, the body of the
" general discussion thread will be according to the parameter. All the other
" arguments must be present in the cache, and they will be used from there.
" In case there are missing arguments, an error will be printed to the screen.
" In order to fill the arguments in the cache, @command(MRInterfaceSetCache) can
" be used.
"
" @usage [body] [project_id] [merge_request_id]
" Add a general discussion thread to gitlab. In this form, the general
" discussion thread that will be added will have all the arguments as given from
" the ex-command.
"
" @usage [body] [private_token] [project_id] [merge_request_id]
" This is the same as the previous form except that in this form the
" [private_token] is inserted as well. When run with this form, the private
" token that will be inserted will be used, ignoring the global private token.
command -nargs=* MRInterfaceAddGeneralDiscussionThread call mr_interface#AddGeneralDiscussionThread(<f-args>)
" MRInterfaceAddGeneralDiscussionThread }}}

" MRInterfaceAddCodeDiscussionThread {{{
""
" @usage
" Add a code discussion thread into a gitlab MR.
" A code discussion thread is a resolvable comment that is linked to specific
" lines in a file in the MR.
" If run without arguments, this function works interactively (asks you for all
" the needed arguments during the command run and add them as you insert them).
" Once all the arguments are inserted, the new discussion thread will be added
" to the gitlab MR.
" This command will get the body of the comment from a new buffer (by
" default). To read more about it, read @section(inserting-body).
"
" @usage [body] [base_sha] [start_sha] [head_sha] [old_path] [new_path] [old_line] [new_line] [project_id] [merge_request_id]
" Add a code discussion thread to gitlab. In this form, the discussion thread
" that will be added will have all the arguments as given from the
" ex-command. This command is filled with a lot of arguments. Almost always it
" will be easier to use the interactive form of this command. (Here mainly for
" automations if needed).
"
" @usage [body] [base_sha] [start_sha] [head_sha] [old_path] [new_path] [old_line] [new_line] [gitlab_private_token] [project_id] [merge_request_id]
" This is the same as the previous form except that in this form the
" [private_token] is inserted as well. When run with this form, the private
" token that will be inserted will be used, ignoring the global private token.
command -nargs=* MRInterfaceAddCodeDiscussionThread call mr_interface#AddCodeDiscussionThread(<f-args>)
" MRInterfaceAddCodeDiscussionThread }}}

" MRInterfaceAddCodeDiscussionThreadOnOldCode {{{
""
" @usage
" Add a new code discussion thread on old code.
" This function will add get the comment from you (using temp buffer, read
" @section(inserting-body) for more information), and then add a comment with
" this information on the current line of code on the file, assuming that the
" file is an old code (the comment will appear on the file before the change
" that was done in this commit).
" This command works for old code only. Old code can be code on file that was
" deleted during this merge request, it can be code that was changed on existing
" file during this merge request (when looking at the old file), and it can be
" on code that was deleted in an existing file during this merge request.
"
" @usage [body]
" Same as the previous command, but in this form it get the body of the new
" discussion thread from the command, not interactively from the user.
"
" @usage [body] [base_sha] [start_sha] [head_sha] [project_id] [merge_request_id]
" Same as the previous command, but in this form it gets all the arguments from
" the command, not interactively from the user.
"
" @usage [body] [base_sha] [start_sha] [head_sha] [project_id] [merge_request_id] [gitlab_private_token]
" The same as the command above, but this form gets the private token as
" parameter as well.
command -nargs=* MRInterfaceAddCodeDiscussionThreadOnOldCode call mr_interface#AddCodeDiscussionThreadOnOldCode(<f-args>)
" MRInterfaceAddCodeDiscussionThreadOnOldCode }}}

" MRInterfaceAddCodeDiscussionThreadOnNewCode {{{
""
" @usage
" Add a new code discussion thread on new code.
" This function will add get the comment from you (using temp buffer, read
" @section(inserting-body) for more information), and then add a comment with
" this information on the current line of code on the file, assuming that the
" file is an new code (the comment will appear on the file after the change
" that was done in this commit).
" This command works for new code only. New code can be code on file that was
" added during this merge request, it can be code that was changed on existing
" file during this merge request, and it can be on code that was added in an
" existing file during this merge request.
"
" @usage [body]
" Same as the previous command, but in this form it get the body of the new
" discussion thread from the command, not interactively from the user.
"
" @usage [body] [base_sha] [start_sha] [head_sha] [project_id] [merge_request_id]
" Same as the previous command, but in this form it gets all the arguments from
" the command, not interactively from the user.
"
" @usage [body] [base_sha] [start_sha] [head_sha] [project_id] [merge_request_id] [gitlab_private_token]
" The same as the command above, but this form gets the private token as
" parameter as well.
command -nargs=* MRInterfaceAddCodeDiscussionThreadOnNewCode call mr_interface#AddCodeDiscussionThreadOnNewCode(<f-args>)
" MRInterfaceAddCodeDiscussionThreadOnNewCode }}}

" MRInterfaceResetCache {{{
""
" @usage
" Reset the cache of the plugin.
"
" For more information about the cache mechanism, see @section(cache).
command -nargs=0 MRInterfaceResetCache call mr_interface#ResetCache()
" MRInterfaceResetCache }}}

" MRInterfaceSetCache {{{
""
" @usage
" Set all the keys in the cache, interactively.
" This function will ask the user to insert values for all the keys of the
" cache. This can be used in order to set all the values of the cache in the
" start, and from there on just count on that they will stay the same.
" This function is interactive, and it doesn't have non-interactive option.
"
" For more information about the cache mechanism, see @section(cache).
command -nargs=0 MRInterfaceSetCache call mr_interface#SetCache()
" MRInterfaceSetCache }}}

" MRInterfaceUpdateValueInCache {{{
""
" @usage [key] [value]
" Add the given [value] into the cache as the value for [key].
" This command can be used to set only a specific key in the cache (differently
" from the command of @command(MRInterfaceSetCache) that updates all the
" values in the cache).
" The value of [key] must be a valid entry in the cache. If it won't be valid
" value from the cache, the command with fail with proper error.
"
" For more information about the cache mechanism, see @section(cache).
command -nargs=+ MRInterfaceUpdateValueInCache call mr_interface#UpdateValueInCache(<f-args>)
" MRInterfaceUpdateValueInCache }}}

" MRInterfaceAddDefaultToCache {{{
""
" @usage
" Add all the default values that the plugin can calculate into the cache.
"
" @usage [key]
" Add the default value for the given key into the cache.
"
" For more information about the cache mechanism, see @section(cache).
command -nargs=? MRInterfaceAddDefaultToCache call mr_interface#AddDefaultToCache(<f-args>)
" MRInterfaceAddDefaultToCache }}}

" Commands }}}
