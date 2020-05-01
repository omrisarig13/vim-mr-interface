" This file includes all the different commands of the plugin.

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

""
" @usage
" Add a comment into a gitlab MR.
" If run without arguments, this function works interactively (asks you for all
" the needed arguments during the command run and add them as you insert them).
" Once all the arguments are inserted, the comment will be added to the gitlab
" MR.
"
" @usage [body] [project_id] [merge_request_id]
" Add a comment to gitlab. In this form, the comment that will be added will
" have all the arguments as given from the ex-command.
"
" @usage [body] [private_token] [project_id] [merge_request_id]
" This is the same as the previous form except that in this form the
" private_token is inserted as well. When run with this form, the private token
" that will be inserted will be used, ignoring the global private token.
command -nargs=* MRInterfaceAddComment call mr_interface#AddComment(<f-args>)

""
" @usage
" Add a general discussion thread into a gitlab MR.
" A general discussion thread is the same as comment, but it can be resolved.
" If run without arguments, this function works interactively (asks you for all
" the needed arguments during the command run and add them as you insert them).
" Once all the arguments are inserted, the new discussion thread will be added
" to the gitlab MR.
"
" @usage [body] [project_id] [merge_request_id]
" Add a general discussion thread to gitlab. In this form, the general
" discussion thread that will be added will have all the arguments as given from
" the ex-command.
"
" @usage [body] [private_token] [project_id] [merge_request_id]
" This is the same as the previous form except that in this form the
" private_token is inserted as well. When run with this form, the private token
" that will be inserted will be used, ignoring the global private token.
command -nargs=* MRInterfaceAddGeneralDiscussionThread call mr_interface#AddGeneralDiscussionThread(<f-args>)

""
" @usage
" Add a code discussion thread into a gitlab MR.
" A code discussion thread is a resolvable comment that is linked to specific
" lines in a file in the MR.
" If run without arguments, this function works interactively (asks you for all
" the needed arguments during the command run and add them as you insert them).
" Once all the arguments are inserted, the new discussion thread will be added
" to the gitlab MR.
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
" private_token is inserted as well. When run with this form, the private token
" that will be inserted will be used, ignoring the global private token.
command -nargs=* MRInterfaceAddCodeDiscussionThread call mr_interface#AddCodeDiscussionThread(<f-args>)

""
" @usage
" Reset the cache of the plugin.
" TODO: Add a link to another section, explaining the basic information about
" how the cache of the plugin works.
command -nargs=0 MRInterfaceResetCache call mr_interface#ResetCache()

""
" @usage
" Set all the keys in the cache, interactively.
" This function will ask the user to insert values for all the keys of the
" cache. This can be used in order to set all the values of the cache in the
" start, and from there on just count on that they will stay the same.
" This function is interactive, and it doesn't have non-interactive option.
"
" TODO: Add a link to another section, explaining the basic information about
" how the cache of the plugin works.
command -nargs=0 MRInterfaceSetCache call mr_interface#SetCache()
