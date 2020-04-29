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
" @usage [body] [private_token] [project_id] [merge_request_id]
" Add a comment to gitlab. In this form, the comment that will be added will
" have all the arguments as given from the ex-command.
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
" @usage [body] [private_token] [project_id] [merge_request_id]
" Add a comment to gitlab. In this form, the discussion thread that will be
" added will have all the arguments as given from the ex-command.
command -nargs=* MRInterfaceAddGeneralDiscussionThread call mr_interface#AddGeneralDiscussionThread(<f-args>)
