" Variables {{{

" Constant Global Variables {{{

""
" An enum that will include all the possible commands.
" @private
let s:gitlab_actions = maktaba#enum#Create([
            \ 'ADD_COMMENT',
            \ 'ADD_GENERAL_DISCUSSION_THREAD',
            \ 'ADD_CODE_DISCUSSION_THREAD'])

""
" The string for asking the user for a given key when there isn't any cache for
" this value.
" @private
let s:insert_string_without_default = "Insert value for %s: "

""
" The string for asking the user for a given key when there is a value in the
" cache for this value.
" @private
let s:insert_string_with_default = "Insert value for %s [%s]: "

""
" The string for telling the user that a command is already in progress
let s:command_in_progress_error = "Another command is running. Can't run "
            \ . "multiple command at the same time"

" Constant Global Variables }}}

" Global Variables {{{

""
" All the configured arguments.
" @private
let s:plugin = maktaba#plugin#Get('vim-mr-interface')

if !exists("s:cache")
    ""
    " A cache that will be used to save old values inserted by the user.
    "
    " Many of the command in the plugin will run a lot of times with most of the
    " same arguments. In order to make it easier for the user to use the plugin,
    " the plugin will maintain a simple cache with the last inserted value in
    " any such field.
    "
    " The values of the cache are being set here explicitly on purpose, in order
    " to let functions iterate over them if needed, even when they are not set.
    "
    " This is not a configurable variable on purpose. The user should change
    " this variable only by using the specific callbacks of the plugin, it
    " should not be changed directly from the user, since it might break things
    " in the plugin.
    "
    " Whenever you change any of the values here, make sure to update the
    " documentation in the flags file as well. This is duplication and ugly, but
    " I couldn't find a way to make vimdoc include only part of the file, so it
    " will stay there for now.
    " @private
    let s:cache = {
                \ 'base sha': '',
                \ 'start sha': '',
                \ 'head sha': '',
                \ 'project id': '',
                \ 'merge request id': '',
                \ 'gitlab private token': ''}
endif

if !exists("s:is_in_command")
    ""
    " v:true in case the plugin is in the middle of command, v:false otherwise.
    " This is important because commands doesn't always end when the function
    " returns (for example, when waiting for output from buffer), so this flag
    " will make sure that commands aren't mangled together.
    let s:is_in_command = v:false
endif

" Global Variables }}}

" Variables }}}

" Functions {{{

" Internal Functions {{{

" Add Comment {{{

" s:InteractiveAddCommentListArgumentAdapter {{{
""
" An adapter to the function of s:InteractiveAddComment that gets an argument of
" list and discards it.
" Return whether the command that run has finished executing.
function! s:InteractiveAddCommentListArgumentAdapter(arguments_list)
    return s:InteractiveAddComment()
endfunction
" s:InteractiveAddCommentListArgumentAdapter }}}

" s:InteractiveAddComment {{{
""
" Add a comment to a gitlab MR interactively.
"
" This functions asks the user to insert all the needed information in order to
" add a comment, and then adds this comment to the gitlab's MR.
" Return whether the command that run has finished executing.
function! s:InteractiveAddComment()
    return s:RunFunctionWithInteractiveBody(function('s:InteractiveAddCommentWithBody'))
endfunction
" s:InteractiveAddComment }}}

" s:InteractiveAddCommentWithBody {{{
""
" Add the comment interactively when the only value present is the body.
" This function was created to support multiple ways to get the body from the
" user.
" In case the body is empty, no command will run.
" Return whether the command that run has finished executing.
function! s:InteractiveAddCommentWithBody(body)
    if empty(a:body)
        return v:true
    endif

    let l:content = s:TurnBodyToContent(a:body)
    let l:gitlab_authentication = s:InteractiveGetGitlabAutentication()
    let l:merge_request_information = s:InteractiveGetMergeRequestInformation()

    " Add the comment.
    return s:RunGitlabAction(
        \ l:content,
        \ l:gitlab_authentication,
        \ l:merge_request_information,
        \ s:gitlab_actions.ADD_COMMENT)
endfunction
" s:InteractiveAddCommentWithBody }}}

" s:AddCommentListArgumentAdapter {{{
""
" An adapter to the function of s:AddComment that gets the arguments as a list
" instead of as separated arguments.
" Return whether the command that run has finished executing.
function! s:AddCommentListArgumentAdapter(arguments_list)
    return s:AddComment(
        \ a:arguments_list[0],
        \ a:arguments_list[1],
        \ a:arguments_list[2])
endfunction
" s:AddCommentListArgumentAdapter }}}

" s:AddCommentWithBodyListArgumentAdapter {{{
""
" An adepter to the function s:AddCommentWithBody that get the argument as
" a list and passes it to the regular function.
" Return whether the command that run has finished executing.
function! s:AddCommentWithBodyListArgumentAdapter(arguments_list)
    return s:AddCommentWithBody(a:arguments_list[0])
endfunction
" s:AddCommentWithBodyListArgumentAdapter }}}

" s:AddCommentWithBody {{{
""
" Add a new comment with the given body.
" This function get all the other arguments from the cache.
" @throws String Error in case one (or more) of the arguments are not in the
"         cache.
" Return whether the command that run has finished executing.
function! s:AddCommentWithBody(comment_body)
    call s:VerifyInCache(['project id', 'merge request id'])

    return s:AddComment(
        \ a:comment_body,
        \ s:cache['project id'],
        \ s:cache['merge request id'])
endfunction
" s:AddCommentWithBody }}}

" s:AddComment {{{
""
" Add the given comment into the given gitlab's MR.
" Return whether the command that run has finished executing.
function! s:AddComment(
            \ comment_body,
            \ project_id,
            \ merge_request_id)
    return s:AddCommentWithPrivateToken(
                \ a:comment_body,
                \ s:GetGitlabPrivateTokenFromGlobal(),
                \ a:project_id,
                \ a:merge_request_id)
endfunction
" s:AddComment }}}

" s:AddCommentWithPrivateTokenListArgumentAdapter {{{
""
" An adapter to the function of s:AddCommentWithPrivateToken that gets the
" arguments as a list instead of as separated arguments.
" Return whether the command that run has finished executing.
function! s:AddCommentWithPrivateTokenListArgumentAdapter(arguments_list)
    return s:AddCommentWithPrivateToken(
        \ a:arguments_list[0],
        \ a:arguments_list[1],
        \ a:arguments_list[2],
        \ a:arguments_list[3])
endfunction
" s:AddCommentWithPrivateTokenListArgumentAdapter }}}

" s:AddCommentWithPrivateToken {{{
""
" Add the given comment into the given gitlab's MR.
" Return whether the command that run has finished executing.
function! s:AddCommentWithPrivateToken(
            \ comment_body,
            \ gitlab_private_token,
            \ project_id,
            \ merge_request_id)
    return s:RunGitlabAction(
        \ {'body': a:comment_body},
        \ {'private_token':a:gitlab_private_token},
        \ {'project_id': a:project_id, 'merge_request_id': a:merge_request_id},
        \ s:gitlab_actions.ADD_COMMENT)
endfunction
" s:AddCommentWithPrivateToken }}}

" Add Comment }}}

" Add General Discussion Thread {{{

" s:InteractiveAddGeneralDiscussionThreadListArgumentAdapter {{{
""
" An adapter to the function of s:InteractiveAddGeneralDiscussionThread that get
" an argument of list and discards it.
" Return whether the command that run has finished executing.
function! s:InteractiveAddGeneralDiscussionThreadListArgumentAdapter(
            \ list_alguments)
    return s:InteractiveAddGeneralDiscussionThread()
endfunction
" s:InteractiveAddGeneralDiscussionThreadListArgumentAdapter }}}

" s:InteractiveAddGeneralDiscussionThread {{{
""
" Add a general discussion thread to a gitlab MR interactively.
"
" This functions asks the user to insert all the needed information in order to
" add a comment, and then adds this comment to the gitlab's MR.
" Return whether the command that run has finished executing.
function! s:InteractiveAddGeneralDiscussionThread()
    return s:RunFunctionWithInteractiveBody(
        \ function('s:InteractiveAddGeneralDiscussionThreadWithBody'))
endfunction
" s:InteractiveAddGeneralDiscussionThread }}}

" s:InteractiveAddGeneralDiscussionThreadWithBody {{{
""
" Add a general discussion thread to a gitlab MR interactively with the body
" given to it.
"
" This functions asks the user to insert all the needed information (except the
" body)in order to add a comment, and then adds this comment to the gitlab's MR.
" Return whether the command that run has finished executing.
function! s:InteractiveAddGeneralDiscussionThreadWithBody(body)
    if empty(a:body)
        return v:true
    endif

    " Get all the comments arguments.
    let l:content = s:TurnBodyToContent(a:body)
    let l:gitlab_authentication = s:InteractiveGetGitlabAutentication()
    let l:merge_request_information = s:InteractiveGetMergeRequestInformation()

    " Add the comment.
    return s:RunGitlabAction(
        \ l:content,
        \ l:gitlab_authentication,
        \ l:merge_request_information,
        \ s:gitlab_actions.ADD_GENERAL_DISCUSSION_THREAD)
endfunction
" s:InteractiveAddGeneralDiscussionThreadWithBody }}}

" s:AddGeneralDiscussionThreadWithBodyListArgumentAdapter {{{
""
" An adepter to the function s:AddGeneralDiscussionThreadWithBody that get the
" argument as a list and passes it to the regular function.
" Return whether the command that run has finished executing.
function! s:AddGeneralDiscussionThreadWithBodyListArgumentAdapter(
            \ arguments_list)
    return s:AddGeneralDiscussionThreadWithBody(a:arguments_list[0])
endfunction
" s:AddGeneralDiscussionThreadWithBodyListArgumentAdapter }}}

" s:AddGeneralDiscussionThreadWithBody {{{
""
" Add the given comment into the given gitlab's MR.
" This function get all the other arguments from the cache.
" @throws String Error in case one (or more) of the arguments are not in the
"         cache.
" Return whether the command that run has finished executing.
function! s:AddGeneralDiscussionThreadWithBody(discussion_thread_body)
    call s:VerifyInCache(['project id', 'merge request id'])

    return s:AddGeneralDiscussionThread(
        \ a:discussion_thread_body,
        \ s:cache['project id'],
        \ s:cache['merge request id'])
endfunction
" s:AddGeneralDiscussionThreadWithBody }}}

" s:AddGeneralDiscussionThreadListArgumentAdapter {{{
""
" An adapter to the function of s:AddGeneralDiscussionThread that gets
" the arguments as a list.
" Return whether the command that run has finished executing.
function! s:AddGeneralDiscussionThreadListArgumentAdapter(arguments_list)
    return s:AddGeneralDiscussionThread(
                \ a:arguments_list[0],
                \ a:arguments_list[1],
                \ a:arguments_list[2])
endfunction
" s:AddGeneralDiscussionThreadListArgumentAdapter }}}

" s:AddGeneralDiscussionThread {{{
""
" Add the given comment into the given gitlab's MR.
" Return whether the command that run has finished executing.
function! s:AddGeneralDiscussionThread(
            \ discussion_thread_body,
            \ project_id,
            \ merge_request_id)
    return s:AddGeneralDiscussionThreadWithPrivateToken(
                \ a:discussion_thread_body,
                \ s:GetGitlabPrivateTokenFromGlobal(),
                \ a:project_id,
                \ a:merge_request_id)
endfunction
" s:AddGeneralDiscussionThread }}}

" s:AddGeneralDiscussionThreadWithPrivateTokenListArgumentAdapter {{{
""
" An adapter to the function of s:AddGeneralDiscussionThreadWithPrivateToken
" that gets the arguments as a list.
" Return whether the command that run has finished executing.
function! s:AddGeneralDiscussionThreadWithPrivateTokenListArgumentAdapter(
            \ arguments_list)
    return s:AddGeneralDiscussionThreadWithPrivateToken(
                \ a:arguments_list[0],
                \ a:arguments_list[1],
                \ a:arguments_list[2],
                \ a:arguments_list[3])
endfunction
" s:AddGeneralDiscussionThreadWithPrivateTokenListArgumentAdapter }}}

" s:AddGeneralDiscussionThreadWithPrivateToken {{{
""
" Add the given comment into the given gitlab's MR.
" Return whether the command that run has finished executing.
function! s:AddGeneralDiscussionThreadWithPrivateToken(
            \ discussion_thread_body,
            \ gitlab_private_token,
            \ project_id,
            \ merge_request_id)
    return s:RunGitlabAction(
        \ {'body': a:discussion_thread_body},
        \ {'private_token': a:gitlab_private_token},
        \ {'project_id': a:project_id, 'merge_request_id': a:merge_request_id},
        \ s:gitlab_actions.ADD_GENERAL_DISCUSSION_THREAD)
endfunction
" s:AddGeneralDiscussionThreadWithPrivateToken }}}

" Add General Discussion Thread }}}

" Add Code Discussion Thread {{{

" Not Connected To Code {{{

" s:InteractiveAddCodeDiscussionThreadListArgumentAdapter {{{
""
" A adapter function for s:InteractiveAddCodeDiscussionThread that get a list as
" argument and calls the original function.
" Return whether the command that run has finished executing.
function! s:InteractiveAddCodeDiscussionThreadListArgumentAdapter(
            \ list_argument)
    return s:InteractiveAddCodeDiscussionThread()
endfunction
" s:InteractiveAddCodeDiscussionThreadListArgumentAdapter }}}

" s:InteractiveAddCodeDiscussionThread {{{
""
" Add a code discussion thread to a gitlab MR interactively.
"
" This functions asks the user to insert all the needed information in order to
" add a code discussion thread, and then adds this new discussion thread to the
" gitlab's MR.
" Return whether the command that run has finished executing.
function! s:InteractiveAddCodeDiscussionThread()
    return s:RunFunctionWithInteractiveBody(
        \ function('s:InteractiveAddCodeDiscussionThreadWithBody'))
endfunction
" s:InteractiveAddCodeDiscussionThread }}}

" s:InteractiveAddCodeDiscussionThreadWithBody {{{
""
" Add a code discussion thread to a gitlab MR interactively with the given body.
"
" This functions asks the user to insert all the needed information (except the
" body) in order to add a code discussion thread, and then adds this new
" discussion thread to the gitlab's MR.
" Return whether the command that run has finished executing.
function! s:InteractiveAddCodeDiscussionThreadWithBody(body)
    " Don't run commands with empty body. This is code duplication with the
    " check in InteractiveAddCodeDiscussionThreadWithBodyAndPosition, but it
    " should be here as well in order to let the user finish the command earlier
    " (since he needs to insert parameters in case it won't finish now).
    if empty(a:body)
        return v:true
    endif

    let l:code_position = s:InteractiveGetCodePosition()

    return s:InteractiveAddCodeDiscussionThreadWithBodyAndPosition(
        \ a:body,
        \ l:code_position)
endfunction
" s:InteractiveAddCodeDiscussionThreadWithBody }}}

" s:InteractiveAddCodeDiscussionThreadWithBodyAndPosition {{{
""
" Interactively add the code discussion thread according to the body of the
" comment and the position of the comment.
function! s:InteractiveAddCodeDiscussionThreadWithBodyAndPosition(
            \ body,
            \ code_position)
    " Don't run commands with empty body
    if empty(a:body)
        return v:true
    endif

    " Get all the comments arguments.
    let l:content = s:InteractiveGetCodeDiscussionThreadContet(
        \ a:body,
        \ a:code_position)
    let l:gitlab_authentication = s:InteractiveGetGitlabAutentication()
    let l:merge_request_information = s:InteractiveGetMergeRequestInformation()

    " Add the comment.
    return s:RunGitlabAction(
        \ l:content,
        \ l:gitlab_authentication,
        \ l:merge_request_information,
        \ s:gitlab_actions.ADD_CODE_DISCUSSION_THREAD)
endfunction
" s:InteractiveAddCodeDiscussionThreadWithBodyAndPosition }}}

" s:AddCodeDiscussionThreadListArgumentAdapter {{{
""
" An adapter to the function of s:AddCodeDiscussionThread that get the arguments
" as a list and calls the original function with the right arguments.
" Return whether the command that run has finished executing.
function! s:AddCodeDiscussionThreadListArgumentAdapter(list_arguments)
    return s:AddCodeDiscussionThread(
                \ a:list_arguments[0],
                \ a:list_arguments[1],
                \ a:list_arguments[2],
                \ a:list_arguments[3],
                \ a:list_arguments[4],
                \ a:list_arguments[5],
                \ a:list_arguments[6],
                \ a:list_arguments[7],
                \ a:list_arguments[8],
                \ a:list_arguments[9])
endfunction
" s:AddCodeDiscussionThreadListArgumentAdapter }}}

" s:AddCodeDiscussionThread {{{
""
" Add a code discussion thread to a gitlab MR.
" Return whether the command that run has finished executing.
function! s:AddCodeDiscussionThread(
            \ comment_body,
            \ base_sha,
            \ start_sha,
            \ head_sha,
            \ old_path,
            \ new_path,
            \ old_line,
            \ new_line,
            \ project_id,
            \ merge_request_id)
    return s:AddCodeDiscussionThreadWithPrivateToken(
                \ a:comment_body,
                \ a:base_sha,
                \ a:start_sha,
                \ a:head_sha,
                \ a:old_path,
                \ a:new_path,
                \ a:old_line,
                \ a:new_line,
                \ s:GetGitlabPrivateTokenFromGlobal(),
                \ a:project_id,
                \ a:merge_request_id)
endfunction
" s:AddCodeDiscussionThread }}}

" s:AddCodeDiscussionThreadWithPrivateTokenListArgumentAdapter {{{
""
" An adapter to the function of
" s:AddCodeDiscussionThreadWithPrivateTokenListArgumentAdapter that get the
" arguments as a list and calls the original function with the right arguments.
" Return whether the command that run has finished executing.
function! s:AddCodeDiscussionThreadWithPrivateTokenListArgumentAdapter(
            \ list_argument)
    return s:AddCodeDiscussionThreadWithPrivateToken(
                \ a:list_argument[0],
                \ a:list_argument[1],
                \ a:list_argument[2],
                \ a:list_argument[3],
                \ a:list_argument[4],
                \ a:list_argument[5],
                \ a:list_argument[6],
                \ a:list_argument[7],
                \ a:list_argument[8],
                \ a:list_argument[9],
                \ a:list_argument[10])
endfunction
" s:AddCodeDiscussionThreadWithPrivateTokenListArgumentAdapter }}}

" s:AddCodeDiscussionThreadWithPrivateToken {{{
""
" Add a code discussion thread to a gitlab MR.
" Return whether the command that run has finished executing.
function! s:AddCodeDiscussionThreadWithPrivateToken(
            \ comment_body,
            \ base_sha,
            \ start_sha,
            \ head_sha,
            \ old_path,
            \ new_path,
            \ old_line,
            \ new_line,
            \ gitlab_private_token,
            \ project_id,
            \ merge_request_id)
    let l:content = {}
    call extend(l:content, s:CreatePositionDict(
        \ a:base_sha,
        \ a:start_sha,
        \ a:head_sha,
        \ a:old_path,
        \ a:new_path,
        \ a:old_line,
        \ a:new_line))
    let l:content['body'] = a:comment_body
    return s:RunGitlabAction(
        \ l:content,
        \ {'private_token': a:gitlab_private_token},
        \ {'project_id': a:project_id, 'merge_request_id': a:merge_request_id},
        \ s:gitlab_actions.ADD_CODE_DISCUSSION_THREAD)
endfunction
" s:AddCodeDiscussionThreadWithPrivateToken }}}

" s:InteractiveGetCodeDiscussionThreadContet {{{
""
" Get all the needed information for the content of a discussion thread on the
" code.
function! s:InteractiveGetCodeDiscussionThreadContet(body, code_position)
    let l:all_variables = {}
    call extend(l:all_variables, s:TurnBodyToContent(a:body))
    call extend(
        \ l:all_variables,
        \ s:InteractiveGetPositionWithCodeParameter(a:code_position))
    return l:all_variables
endfunction
" s:InteractiveGetCodeDiscussionThreadContet }}}

" Not Connected To Code }}}

" Old Code {{{

" s:InteractiveAddCodeDiscussionThreadOnOldCodeListArgumentAdapter {{{
""
" A adapter function for s:InteractiveAddCodeDiscussionThreadOnOldCode that get
" a list as argument and calls the original function.
" Return whether the command that run has finished executing.
function! s:InteractiveAddCodeDiscussionThreadOnOldCodeListArgumentAdapter(
            \ list_argument)
    return s:InteractiveAddCodeDiscussionThreadOnOldCode()
endfunction
" s:InteractiveAddCodeDiscussionThreadOnOldCodeListArgumentAdapter }}}

" s:InteractiveAddCodeDiscussionThreadOnOldCode {{{
""
" A function that will add a comment on old code, getting the arguments for the
" comment interactively from the user.
" Return whether the command that run has finished executing.
function! s:InteractiveAddCodeDiscussionThreadOnOldCode()
    let l:current_position = s:GetCurrentCodePositionWithFugitive()

    return s:InteractiveAddCodeDiscussionThreadWithPosition(
        \ {'old_path': l:current_position['full_file_path'],
        \  'new_path': l:current_position['full_file_path'],
        \  'old_line': l:current_position['line_number'],
        \  'new_line': 'null'})
endfunction
" s:InteractiveAddCodeDiscussionThreadOnOldCode }}}

" s:AddCodeDiscussionThreadOnOldCodeListArgumentAdapter {{{
""
" An adapter to the function of s:AddCodeDiscussionThreadOnOldCode that get the
" arguments as a list and calls the original function with the right arguments.
" Return whether the command that run has finished executing.
function! s:AddCodeDiscussionThreadOnOldCodeListArgumentAdapter(list_arguments)
    return s:AddCodeDiscussionThreadOnOldCode(
                \ a:list_arguments[0],
                \ a:list_arguments[1],
                \ a:list_arguments[2],
                \ a:list_arguments[3],
                \ a:list_arguments[4],
                \ a:list_arguments[5])
endfunction
" s:AddCodeDiscussionThreadOnOldCodeListArgumentAdapter }}}

" s:AddCodeDiscussionThreadOnOldCode {{{
""
" Add a code discussion thread to a gitlab MR according to the current position
" of the cursor on an old file.
" Return whether the command that run has finished executing.
function! s:AddCodeDiscussionThreadOnOldCode(
            \ comment_body,
            \ base_sha,
            \ start_sha,
            \ head_sha,
            \ project_id,
            \ merge_request_id)
    return s:AddCodeDiscussionThreadOnOldCodeWithPrivateToken(
                \ a:comment_body,
                \ a:base_sha,
                \ a:start_sha,
                \ a:head_sha,
                \ s:GetGitlabPrivateTokenFromGlobal(),
                \ a:project_id,
                \ a:merge_request_id)
endfunction
" s:AddCodeDiscussionThreadOnOldCode }}}

" s:AddCodeDiscussionThreadOnOldCodeWithPrivateTokenListArgumentAdapter {{{
""
" An adapter to the function of
" s:AddCodeDiscussionThreadOnOldCodeWithPrivateToken that get the arguments as
" a list and calls the original function with the right arguments.
" Return whether the command that run has finished executing.
function! s:AddCodeDiscussionThreadOnOldCodeWithPrivateTokenListArgumentAdapter(
            \ list_arguments)
    return s:AddCodeDiscussionThreadOnOldCode(
                \ a:list_arguments[0],
                \ a:list_arguments[1],
                \ a:list_arguments[2],
                \ a:list_arguments[3],
                \ a:list_arguments[4],
                \ a:list_arguments[5],
                \ a:list_arguments[6])
endfunction
" s:AddCodeDiscussionThreadOnOldCodeWithPrivateTokenListArgumentAdapter }}}

" s:AddCodeDiscussionThreadOnOldCodeWithPrivateToken {{{
""
" Add a code discussion thread to a gitlab MR according to the current position
" of the cursor on an old file.
" Return whether the command that run has finished executing.
function! s:AddCodeDiscussionThreadOnOldCodeWithPrivateToken(
            \ comment_body,
            \ base_sha,
            \ start_sha,
            \ head_sha,
            \ gitlab_private_token,
            \ project_id,
            \ merge_request_id)
    let l:current_position = s:GetCurrentCodePositionWithFugitive()

    return s:AddCodeDiscussionThreadWithPrivateToken(
        \ a:comment_body,
        \ a:base_sha,
        \ a:start_sha,
        \ a:head_sha,
        \ l:current_position['full_file_path'],
        \ l:current_position['full_file_path'],
        \ l:current_position['line_number'],
        \ 'null',
        \ a:gitlab_private_token,
        \ a:project_id,
        \ a:merge_request_id)
endfunction
" s:AddCodeDiscussionThreadOnOldCodeWithPrivateToken }}}

" s:AddCodeDiscussionThreadOnOldCodeWithBodyListArgumentAdapter {{{
""
" An adepter to the function s:AddCodeDiscussionThreadOnOldCodeWithBody that get
" the argument as a list and passes it to the regular function.
" Return whether the command that run has finished executing.
function! s:AddCodeDiscussionThreadOnOldCodeWithBodyListArgumentAdapter(
            \ arguments_list)
    return s:AddCodeDiscussionThreadOnOldCodeWithBody(a:arguments_list[0])
endfunction
" s:AddCodeDiscussionThreadOnOldCodeWithBodyListArgumentAdapter }}}

" s:AddCodeDiscussionThreadOnOldCodeWithBody {{{
""
" Add a new code discussion thread on the current position on the old code into
" the gitlab MR.
" This function get all the other arguments from the cache.
" @throws String Error in case one (or more) of the arguments are not in the
"         cache.
" Return whether the command that run has finished executing.
function! s:AddCodeDiscussionThreadOnOldCodeWithBody(discussion_thread_body)
    call s:VerifyInCache([
                \ 'base sha',
                \ 'start sha',
                \ 'head sha',
                \ 'project id',
                \ 'merge request id'])

    return s:AddCodeDiscussionThreadOnOldCode(
        \ a:discussion_thread_body,
        \ s:cache['base sha'],
        \ s:cache['start sha'],
        \ s:cache['head sha'],
        \ s:cache['project id'],
        \ s:cache['merge request id'])
endfunction
" s:AddCodeDiscussionThreadOnOldCodeWithBody }}}

" Old Code }}}

" New Code {{{

" s:InteractiveAddCodeDiscussionThreadOnNewCodeListArgumentAdapter {{{
""
" A adapter function for s:InteractiveAddCodeDiscussionThreadOnNewCode that get
" a list as argument and calls the original function.
" Return whether the command that run has finished executing.
function! s:InteractiveAddCodeDiscussionThreadOnNewCodeListArgumentAdapter(
            \ list_argument)
    return s:InteractiveAddCodeDiscussionThreadOnNewCode()
endfunction
" s:InteractiveAddCodeDiscussionThreadOnNewCodeListArgumentAdapter }}}

" s:InteractiveAddCodeDiscussionThreadOnNewCode {{{
""
" A function that will add a comment on new code, getting the arguments for the
" comment interactively from the user.
" Return whether the command that run has finished executing.
function! s:InteractiveAddCodeDiscussionThreadOnNewCode()
    let l:current_position = s:GetCurrentCodePositionWithFugitive()

    return s:InteractiveAddCodeDiscussionThreadWithPosition(
        \ {'old_path': l:current_position['full_file_path'],
        \  'new_path': l:current_position['full_file_path'],
        \  'old_line': 'null',
        \  'new_line': l:current_position['line_number']})
endfunction
" s:InteractiveAddCodeDiscussionThreadOnNewCode }}}

" s:AddCodeDiscussionThreadOnNewCodeListArgumentAdapter {{{
""
" An adapter to the function of s:AddCodeDiscussionThreadOnNewCode that get the
" arguments as a list and calls the original function with the right arguments.
" Return whether the command that run has finished executing.
function! s:AddCodeDiscussionThreadOnNewCodeListArgumentAdapter(list_arguments)
    return s:AddCodeDiscussionThreadOnNewCode(
                \ a:list_arguments[0],
                \ a:list_arguments[1],
                \ a:list_arguments[2],
                \ a:list_arguments[3],
                \ a:list_arguments[4],
                \ a:list_arguments[5])
endfunction
" s:AddCodeDiscussionThreadOnNewCodeListArgumentAdapter }}}

" s:AddCodeDiscussionThreadOnNewCode {{{
""
" Add a code discussion thread to a gitlab MR according to the current position
" of the cursor on an new file.
" Return whether the command that run has finished executing.
function! s:AddCodeDiscussionThreadOnNewCode(
            \ comment_body,
            \ base_sha,
            \ start_sha,
            \ head_sha,
            \ project_id,
            \ merge_request_id)
    return s:AddCodeDiscussionThreadOnNewCodeWithPrivateToken(
                \ a:comment_body,
                \ a:base_sha,
                \ a:start_sha,
                \ a:head_sha,
                \ s:GetGitlabPrivateTokenFromGlobal(),
                \ a:project_id,
                \ a:merge_request_id)
endfunction
" s:AddCodeDiscussionThreadOnNewCode }}}

" s:AddCodeDiscussionThreadOnNewCodeWithPrivateTokenListArgumentAdapter {{{
""
" An adapter to the function of
" s:AddCodeDiscussionThreadOnNewCodeWithPrivateToken that get the arguments as
" a list and calls the original function with the right arguments.
" Return whether the command that run has finished executing.
function! s:AddCodeDiscussionThreadOnNewCodeWithPrivateTokenListArgumentAdapter(
            \ list_arguments)
    return s:AddCodeDiscussionThreadOnNewCode(
                \ a:list_arguments[0],
                \ a:list_arguments[1],
                \ a:list_arguments[2],
                \ a:list_arguments[3],
                \ a:list_arguments[4],
                \ a:list_arguments[5],
                \ a:list_arguments[6])
endfunction
" s:AddCodeDiscussionThreadOnNewCodeWithPrivateTokenListArgumentAdapter }}}

" s:AddCodeDiscussionThreadOnNewCodeWithPrivateToken {{{
""
" Add a code discussion thread to a gitlab MR according to the current position
" of the cursor on an new file.
" Return whether the command that run has finished executing.
function! s:AddCodeDiscussionThreadOnNewCodeWithPrivateToken(
            \ comment_body,
            \ base_sha,
            \ start_sha,
            \ head_sha,
            \ gitlab_private_token,
            \ project_id,
            \ merge_request_id)
    let l:current_position = s:GetCurrentCodePositionWithFugitive()

    return s:AddCodeDiscussionThreadWithPrivateToken(
        \ a:comment_body,
        \ a:base_sha,
        \ a:start_sha,
        \ a:head_sha,
        \ l:current_position['full_file_path'],
        \ l:current_position['full_file_path'],
        \ 'null',
        \ l:current_position['line_number'],
        \ a:gitlab_private_token,
        \ a:project_id,
        \ a:merge_request_id)
endfunction
" s:AddCodeDiscussionThreadOnNewCodeWithPrivateToken }}}

" s:AddCodeDiscussionThreadOnNewCodeWithBodyListArgumentAdapter {{{
""
" An adepter to the function s:AddCodeDiscussionThreadOnNewCodeWithBody that get
" the argument as a list and passes it to the regular function.
" Return whether the command that run has finished executing.
function! s:AddCodeDiscussionThreadOnNewCodeWithBodyListArgumentAdapter(
            \ arguments_list)
    return s:AddCodeDiscussionThreadOnNewCodeWithBody(a:arguments_list[0])
endfunction
" s:AddCodeDiscussionThreadOnNewCodeWithBodyListArgumentAdapter }}}

" s:AddCodeDiscussionThreadOnNewCodeWithBody {{{
""
" Add a new code discussion thread on the current position on the new code into
" the gitlab MR.
" This function get all the other arguments from the cache.
" @throws String Error in case one (or more) of the arguments are not in the
"         cache.
" Return whether the command that run has finished executing.
function! s:AddCodeDiscussionThreadOnNewCodeWithBody(discussion_thread_body)
    call s:VerifyInCache([
                \ 'base sha',
                \ 'start sha',
                \ 'head sha',
                \ 'project id',
                \ 'merge request id'])

    return s:AddCodeDiscussionThreadOnNewCode(
        \ a:discussion_thread_body,
        \ s:cache['base sha'],
        \ s:cache['start sha'],
        \ s:cache['head sha'],
        \ s:cache['project id'],
        \ s:cache['merge request id'])
endfunction
" s:AddCodeDiscussionThreadOnNewCodeWithBody }}}

" New Code }}}

" General {{{

" s:InteractiveAddCodeDiscussionThreadWithPosition {{{
""
" Interactively add a code discussion thread on the given line.
" Return whether the command that run has finished executing.
" The position should be a dictionary with the values for 'old_path',
" 'new_path', 'old_line', 'new_line'.
function! s:InteractiveAddCodeDiscussionThreadWithPosition(position)
    return s:RunFunctionWithInteractiveBodyAndParameter(
        \ function('s:InteractiveAddCodeDiscussionThreadWithBodyAndPosition'),
        \ a:position,
        \ v:true)
endfunction
" s:InteractiveAddCodeDiscussionThreadWithPosition }}}

" General }}}

" Add Code Discussion Thread }}}

" Gitlab Specific {{{

" Get Data Interactively {{{

" s:InteractiveGetPositionWithCodeParameter {{{
""
" Get the full position (git and code positions) for a code discussion comment.
function! s:InteractiveGetPositionWithCodeParameter(code_position)
    let l:git_position = s:InteractiveGetGitPosition()

    return s:CreatePositionDict(
        \ l:git_position['base_sha'],
        \ l:git_position['start_sha'],
        \ l:git_position['head_sha'],
        \ a:code_position['old_path'],
        \ a:code_position['new_path'],
        \ a:code_position['old_line'],
        \ a:code_position['new_line'])
endfunction
" s:InteractiveGetPositionWithCodeParameter }}}

" s:InteractiveGetCodePosition {{{
""
" Get the position on the code interactively.
function! s:InteractiveGetCodePosition()
    let l:old_path = input(printf(s:insert_string_without_default, 'old path'))
    let l:new_path = s:InputWithDefault('new path', l:old_path)
    let l:old_line = input(printf(s:insert_string_without_default, 'old line'))
    let l:new_line = input(printf(s:insert_string_without_default, 'new line'))
    return {
        \ 'old_path':l:old_path,
        \ 'new_path':l:new_path,
        \ 'old_line':l:old_line,
        \ 'new_line':l:new_line}
endfunction
" s:InteractiveGetCodePosition }}}

" s:InteractiveGetGitPosition {{{
""
" Get all the needed information for a position on the code for the MR.
function! s:InteractiveGetGitPosition()
    " The arguments of the sha probably won't change, use them from the cache.
    let l:base_sha = s:GetWithCache('base sha')
    let l:start_sha = s:GetWithCache('start sha')
    let l:head_sha = s:GetWithCache('head sha')
    return {
        \ 'base_sha': l:base_sha,
        \ 'start_sha':l:start_sha,
        \ 'head_sha':l:head_sha}
endfunction
" s:InteractiveGetGitPosition }}}

" s:InteractiveGetBodyAsContent {{{
""
" Get the body of the gitlab action in the needed format as content.
" This function should be used for commands that all their content is just the
" 'body' of the command. Such commands are ADD_GENERAL_DISCUSSION_THREAD or
" ADD_COMMENT.
" This function will read the string from the user and set it as return it in
" the needed format for the content adding.
function! s:InteractiveGetBodyAsContent()
    let l:body = input(printf(s:insert_string_without_default, 'body'))
    return {"body" : l:body}
endfunction
" s:InteractiveGetBodyAsContent }}}

" s:InteractiveGetBody {{{
""
" Get the body interactively from the user.
" Returns the body as the user inserted it.
function! s:InteractiveGetBody()
    return input(printf(s:insert_string_without_default, 'body'))
endfunction
" s:InteractiveGetBody }}}

" s:InteractiveGetMergeRequestInformation {{{
""
" Get all the needed information to add something into a merge request.
function! s:InteractiveGetMergeRequestInformation()
    let l:project_id = s:GetWithCache('project id')
    let l:merge_request_id = s:GetMergeRequestId()

    return {'project_id': l:project_id, 'merge_request_id': l:merge_request_id}
endfunction
" s:InteractiveGetMergeRequestInformation }}}

" s:GetMergeRequestId {{{
""
" Get the merge request id interactively.
" In case the merge request id appears in the cache, it will return it from the
" cache. If it is not in the cache, it will try to get it from the current
" branch name. In case it is not the branch name, it will ask the user to insert
" it.
function! s:GetMergeRequestId()
    return s:GetWithCacheAndDefaultMethod(
        \ 'merge request id',
        \ function("s:GetMRFromBranchName"))
endfunction
" s:GetMergeRequestId }}}

" s:InteractiveGetGitlabAutentication {{{
""
" Get all the needed information to authenticate with the gitlab interactively.
"
" Currently, it just asks the user to insert his private token. However, it can
" be changed in the future, for more secure authentication.
function! s:InteractiveGetGitlabAutentication()
    let l:private_token = s:GetGitlabPrivateTokenFromGlobalOrInteractive()

    return {'private_token': l:private_token}
endfunction
" s:InteractiveGetGitlabAutentication }}}h

" s:GetGitlabPrivateTokenFromGlobalOrInteractive {{{
""
" Get the global private token of 'gitlab_private_token'.
" Throws error in case it does not exists.
function! s:GetGitlabPrivateTokenFromGlobalOrInteractive()
    try
        let l:gitlab_private_token = s:GetGitlabPrivateTokenFromGlobal()
    catch /gitlab_private_token variable does not exist/
        let l:gitlab_private_token = s:GetWithCache('gitlab private token')
    endtry
    return l:gitlab_private_token
endfunction
" s:GetGitlabPrivateTokenFromGlobalOrInteractive }}}

" Get Data Interactively }}}

" Commands Interface {{{

" s:CreatePositionDict {{{
""
" Create the position dictionary from all its raw arguments.
function! s:CreatePositionDict(
            \ base_sha,
            \ start_sha,
            \ head_sha,
            \ old_path,
            \ new_path,
            \ old_line,
            \ new_line)
    let l:position_dict = {}
    let position_dict['base_sha'] = a:base_sha
    let position_dict['start_sha'] = a:start_sha
    let position_dict['head_sha'] = a:head_sha
    let position_dict['position_type'] = 'text'
    call s:AddIfNotEmpty(l:position_dict, 'old_path', a:old_path)
    call s:AddIfNotEmpty(l:position_dict, 'new_path', a:new_path)
    call s:AddIfNotEmpty(l:position_dict, 'old_line', a:old_line)
    call s:AddIfNotEmpty(l:position_dict, 'new_line', a:new_line)
    return {"position": l:position_dict}
endfunction
" s:CreatePositionDict }}}

" s:TurnBodyToContent {{{
""
" Turn the string value inserted to the function to the needed value as content.
function! s:TurnBodyToContent(body)
    return {'body' : a:body}
endfunction
" s:TurnBodyToContent }}}

" s:GetGitlabPrivateTokenFromGlobal {{{
""
" Get the global private token of 'gitlab_private_token'.
" Throws error in case it does not exists.
function! s:GetGitlabPrivateTokenFromGlobal()
    let l:gitlab_private_token = s:plugin.Flag('gitlab_private_token')
    if empty(l:gitlab_private_token)
        throw "gitlab_private_token variable does not exist"
    endif
    return l:gitlab_private_token
endfunction
" s:GetGitlabPrivateTokenFromGlobal }}}

" s:RunFunctionWithInteractiveBody {{{
""
" Get the body interactively from the user, then run the function got as
" argument.
" Return whether the command that run has finished executing.
function! s:RunFunctionWithInteractiveBody(function_to_run)
    return s:RunFunctionWithInteractiveBodyAndParameter(
                \ a:function_to_run,
                \ '',
                \ v:false)
endfunction
" s:RunFunctionWithInteractiveBody }}}

" s:RunFunctionWithInteractiveBodyAndParameter {{{
""
" Get the body interactively from the user, then run the function got as
" argument with its argument. In case the argument will be "null" it won't be
" passed to the function. In case the parameter is not used, the command can run
" without it (according to the value of `is_parameter_valid`).
" Return whether the command that run has finished executing.
function! s:RunFunctionWithInteractiveBodyAndParameter(
            \ function_to_run,
            \ function_parameter,
            \ is_parameter_valid)
    if s:plugin.Flag('read_body_from_buffer')
        " Create the buffer
        let l:buffer_id = s:CreateScratchBuffer(
                    \ s:plugin.Flag('body_buffer_height'))

        " Set the rest of the functions to happen once the buffer has been
        " closed.
        let s:function_to_run = a:function_to_run
        let s:function_parameter = a:function_parameter
        let s:is_parameter_valid = a:is_parameter_valid
        execute "autocmd BufWipeout <buffer=" . l:buffer_id . "> call s:GetContentAndRun(" . l:buffer_id . ", s:function_to_run, s:function_parameter, s:is_parameter_valid)"
        execute "autocmd BufWipeout <buffer=" . l:buffer_id . "> call s:DeleteArgument('s:function_to_run')"
        execute "autocmd BufWipeout <buffer=" . l:buffer_id . "> call s:DeleteArgument('s:function_parameter')"
        execute "autocmd BufWipeout <buffer=" . l:buffer_id . "> call s:DeleteArgument('s:is_parameter_valid')"

        " Return false - the command will continue to run once the buffer is
        " closed.
        return v:false
    else
        let l:body = s:InteractiveGetBody()
        if a:is_parameter_valid
            return a:function_to_run(l:body, a:function_parameter)
        else
            return a:function_to_run(l:body)
        endif
    endif
endfunction
" s:RunFunctionWithInteractiveBodyAndParameter }}}

" s:CreateGitlabActionCommand {{{
""
" Creates the needed command in order to run a command on gitlab for the given
" MR.
" This function creates the command from the information given to it. Different
" commands will be created according to the different possible values of
" gitlab_actions.
" The value of content should be a dictionary with all the post parameters that
" should be sent as part of the command.
function! s:CreateGitlabActionCommand(
            \ content,
            \ gitlab_authentication,
            \ merge_request_information,
            \ gitlab_action)
    let l:url = s:CreateGitlabCommandAddress(
        \ a:merge_request_information,
        \ a:gitlab_action)
    let l:authentication = s:CreateGitlabAuthentication(a:gitlab_authentication)
    let l:content = s:CreateCommandContent(a:content)
    return printf(
        \ 'curl -H "Content-Type: application/json" -d ''%s'' --request POST %s %s',
        \ l:content,
        \ l:authentication,
        \ l:url)
endfunction
" s:CreateGitlabActionCommand }}}

" s:CreateCommandContent {{{
""
" Create a string ready to be sent as a content in the POST request of curl.
function! s:CreateCommandContent(content)
    " When running string() on a dictionary, it returns the strings in it with
    " single quote, but CURL needs the strings to be with double quotes. This
    " code replace all the single quote characters to double quotes.
    " TODO: This is a patch, and it is better to fix it to work better in the
    " future.
    return substitute(string(a:content), "'", '"', 'g')
endfunction
" s:CreateCommandContent }}}

" s:CreateGitlabAuthentication {{{
""
" Creates and returns the needed information to add to the curl command in order
" to authenticate with gitlab.
" Currently, the only method that this function supports is by using a private
" token, however, it will be possible to extend it in the future to support more
" (and more secured) authentication ways.
function! s:CreateGitlabAuthentication(
            \ gitlab_authentication)
    return printf(
                \ '--header "PRIVATE-TOKEN: %s"',
                \ a:gitlab_authentication.private_token)
endfunction
" s:CreateGitlabAuthentication }}}

" s:CreateGitlabCommandAddress {{{
""
" Create the needed command in order to add a comment to the given gitlab MR.
function! s:CreateGitlabCommandAddress(
            \ merge_request_information,
            \ gitlab_action)
    return printf(
        \ "https://%s/api/v4/projects/%s/merge_requests/%s/%s?body=note",
        \ s:plugin.Flag('gitlab_server_address'),
        \ a:merge_request_information.project_id,
        \ a:merge_request_information.merge_request_id,
        \ s:GetActionUrl(a:gitlab_action))
endfunction
" s:CreateGitlabCommandAddress }}}

" s:GetActionUrl {{{
""
" Get the needed string to append to the MR for the given command type.
" This function gets one of the values of s:gitlab_actions and returns the
" appropriate string in the URL.
function! s:GetActionUrl(gitlab_action)
    if a:gitlab_action == s:gitlab_actions.ADD_COMMENT
        return "notes"
    elseif a:gitlab_action == s:gitlab_actions.ADD_GENERAL_DISCUSSION_THREAD
        return "discussions"
    elseif a:gitlab_action == s:gitlab_actions.ADD_CODE_DISCUSSION_THREAD
        " This is the same as the if above, but it doesn't must stay that way in
        " the future, so it is better to separate them.
        return "discussions"
    endif
endfunction
" s:GetActionUrl }}}

" s:ValidateCommandOutput {{{
""
" This function checks the output of the command and prints a message
" accordingly.
function! s:ValidateCommandOutput(command_output, success_string, error_string)
    let l:status = s:GetCommandOutputStatus(a:command_output)

    " Print the result according to the status.
    if l:status == "Passed"
        call s:new_line_echom(a:success_string)
    else
        call maktaba#error#Shout(a:error_string . l:status)
    endif
endfunction
" s:ValidateCommandOutput }}}

" s:GetCommandOutputStatus {{{
""
" Check what is the output status of the given command.
"
" The function can return one of the following values:
"  "Passed" - when the command passed.
"  "Bad Request" - The request that was sent was bad - it didn't contain the
"                  needed information.
"  "Unauthorized" - In case the user is not autorized to run the given command.
"  "Not Found" - In case the requested page was not found.
"  "Token Expired" - In case the token is expired.
"  "Invalid Token" - Some unknown error with the token.
"
" @TODO: This function works by checking for common errors. It should instead
"  parse the output and check what is the real status of the command, not just
"  guess common command problems.
function! s:GetCommandOutputStatus(command_output)
    if stridx(a:command_output, '"message":"404') != -1
        return "Not Found"
    elseif stridx(a:command_output, '"message":"400 (Bad request)') != -1
        return "Bad Request"
    elseif stridx(a:command_output, '"message":"401 Unauthorized"') != -1
        return "Unauthorized"
    elseif stridx(a:command_output, '"error_description":"Token is expired.') != -1
        return "Token Expired"
    elseif stridx(a:command_output, '"error":"invalid_token"') != -1
        return "Invalid Token"
    else
        return "Passed"
    endif
endfunction
" s:GetCommandOutputStatus }}}

" Commands Interface }}}

" s:RunGitlabAction {{{
""
" Add the given comment into the given gitlab's MR.
" Return whether the command that run has finished executing.
function! s:RunGitlabAction(
            \ content,
            \ gitlab_authentication,
            \ merge_request_information,
            \ gitlab_action)
    " Create the command.
    let l:command = s:CreateGitlabActionCommand(
        \ a:content,
        \ a:gitlab_authentication,
        \ a:merge_request_information,
        \ a:gitlab_action)

    " Run the command.
    let l:command_result = system(l:command)

    " Check (and print message) about the command's result.
    call s:ValidateCommandOutput(
        \ l:command_result,
        \ "Added comment successfully",
        \ "Could not add comment. Error: ")
    return v:true
endfunction
" s:RunGitlabAction }}}

" Gitlab Specific }}}

" Git Specific {{{

" s:GetCurrentCodePositionWithFugitive {{{
""
" Get the current position of the cursor.
" In case the cursor is inside a file with fugitive-like file name, and the user
" wanted to support fugitive, the position will be on the file as if it were the
" regular file, not the fugitive one.
" The function will return a dict that includes the full file path of the
" current file, and the current line number in this path.
function! s:GetCurrentCodePositionWithFugitive()
    let l:position = s:GetCurrentCodePosition()

    if s:plugin.Flag('support_fugitive_file_names')
        let l:position['full_file_path'] =
            \ s:GetFugitiveRealPath(l:position['full_file_path'])
    endif

    return l:position
endfunction
" s:GetCurrentCodePositionWithFugitive }}}

" s:GetFugitiveRealPath {{{
""
" Get the real path of the file from the repository, in case it is opened as
" a fugitive buffer
function! s:GetFugitiveRealPath(fugitive_path)
    return substitute(
        \ a:fugitive_path,
        \ 'fugitive.*git\/\/[0-9a-fA-F]\{40}\/',
        \ '',
        \ 'g')
endfunction
" s:GetFugitiveRealPath }}}

" s:GetMRFromBranchName {{{
""
" Get the id of the current MR from the name of the current branch.
" It will work in case the user has used the command of MR from `git-extras` (or
" has a name with the same format).
"
" The function returns the number of the MR in case the branch name is right. It
" will return v:null in case the branch is not an MR branch.
function! s:GetMRFromBranchName()
    let l:branch_name = s:GetCurrentBranchName()

    if s:IsMRBranch(l:branch_name)
        return s:GetMRNumberFromMRBranch(l:branch_name)
    endif

    return v:null
endfunction
" s:GetMRFromBranchName }}}

" s:GetCurrentBranchName {{{
""
" Get the name of the current git branch.
function! s:GetCurrentBranchName()
    return system("git branch --show-current")
endfunction
" s:GetCurrentBranchName }}}

" s:IsMRBranch {{{
""
" Check if the current branch is an MR branch.
function! s:IsMRBranch(branch_name)
    if match(a:branch_name, '^mr/[0-9]\+') != -1
        return v:true
    endif

    return v:false
endfunction
" s:IsMRBranch }}}

" s:GetMRNumberFromMRBranch {{{
""
" Get the number of the MR from the name of an MR branch.
function! s:GetMRNumberFromMRBranch(branch_name)
    return str2nr(substitute(a:branch_name, 'mr/\([0-9]\+\).*', '\1', 'g'))
endfunction
" s:GetMRNumberFromMRBranch }}}

" Git Specific }}}

" Vimscript Utils {{{

" Commands Interface {{{

" s:GetArgumentsFromCommandLine {{{
""
" Turn a list of arguments from the ex-command into a real list of arguments.
"
" The original list of arguments is separated by spaces, but some of the words
" there are part of the same argument (according to quotes). This list turn
" a list separated by words to be separated by quotes.
"
" The function gets the list of arguments (according to vim's <f-args>) and
" return a new list that was created according to the quotes and not spaces.
function! s:GetArgumentsFromCommandLine(arguments)
    let l:mutable_arguments = copy(a:arguments)
    let l:result = []

    " Move over the list, concatenating all the variables from the quotes
    " together.
    while len(l:mutable_arguments) != 0
        let l:current_item = lh#command#Fargs2String(l:mutable_arguments)
        call add(l:result, s:RemoveStringQuotes(l:current_item))
    endwhile

    return l:result
endfunction
" s:GetArgumentsFromCommandLine }}}

" s:RemoveStringQuotes {{{
""
" Remove all the quotes from the string.
function! s:RemoveStringQuotes(string)
    return substitute(a:string, "[\"']", '', 'g')
endfunction
" s:RemoveStringQuotes }}}

" s:RunCommandByNumberOfArguments {{{
""
" Check how many arguments were inserted in the command line, and run the
" command with the appropriate number of parameters.
" @throws String Error in case there isn't any command for the wanted number of
"         arguments.
"
" [command_line_arguments] - The arguments derictly from the command (using
"                            <f-args>)
" [commands] - All the possible commands in a dict, where the number of
"              arguments is the key and the wanted function is the value.
" Return whether the command that run has finished.
function! s:RunCommandByNumberOfArguments(command_line_arguments, commands)
    " Get the real arguments.
    let l:real_arguments = s:GetArgumentsFromCommandLine(
                \ a:command_line_arguments)
    let l:number_of_arguments = len(l:real_arguments)

    " If the command in the dictionary, run it.
    if has_key(a:commands, l:number_of_arguments)
        return a:commands[l:number_of_arguments](l:real_arguments)
    else
        " The command is not in the dictionary, raise an error.
        throw("Invalid number of arguments")
    endif
endfunction
" s:RunCommandByNumberOfArguments }}}

" s:EnterCommand {{{
""
" Update the needed variables when entering a new command.
" @throws String Error in case a command is already in progress.
function! s:EnterCommand()
    " Validate no other command running
    if s:is_in_command
        throw s:command_in_progress_error
    endif

    " Update the key.
    let s:is_in_command = v:true
endfunction
" s:EnterCommand }}}

" s:ExitCommand {{{
""
" Update the needed variables when exiting from a command that finished
function! s:ExitCommand()
    " Update the key.
    let s:is_in_command = v:false
endfunction
" s:ExitCommand }}}

" Commands Interface }}}

" s:GetCurrentCodePosition {{{
""
" Get the current position of the cursor.
" The function will return a dict that includes the full file path of the
" current file, and the current line number in this path.
function! s:GetCurrentCodePosition()
    let l:full_file_path = expand('%')
    let l:line_number = line('.')
    return {'full_file_path':l:full_file_path, 'line_number':l:line_number}
endfunction
" s:GetCurrentCodePosition }}}

" s:AddIfNotEmpty {{{
""
" Add the current entry to the dictionary in case the value is not empty.
" This functions assume that a string of `null` is an empty string.
function! s:AddIfNotEmpty(dictionary_to_add, new_key, new_value)
    if !empty(a:new_value) && (a:new_value != 'null')
        let a:dictionary_to_add[a:new_key] = a:new_value
    endif
endfunction
" s:AddIfNotEmpty }}}

" Buffers {{{

" s:CreateScratchBuffer {{{
""
" Create a new scratch buffer in the window.
" Return the id of this new buffer.
function! s:CreateScratchBuffer(height)
    execute a:height . " new"
    setlocal buftype=nofile
    setlocal bufhidden=wipe
    setlocal noswapfile
    return bufnr("%")
endfunction
" s:CreateScratchBuffer }}}

" s:GetContentAndRun {{{
""
" Get the content from the given buffer and continue to run the command.
" This function should be used whenever buffers should run and their content
" should be used. It will continue from the previous content, and end the
" command that started with them.
"
" When this function will end, in case the command really ended, it will call
" the ExitCommand function.
function! s:GetContentAndRun(
            \ buffer_id,
            \ function_to_run,
            \ additional_parameter,
            \ is_additional_parameter_valid)
    " Get the content of the buffer as a single line with characters of `\n` in
    " it. This is done because this is the way that values should be sent over
    " the network when new-lines are needed. The string of '\n' stays the same
    " one (while "\n" turns to newline). It should stay this way.
    let l:buffer_content = s:GetContentFromBuffer(a:buffer_id, '\n')

    " Run the wanted function.
    if a:is_additional_parameter_valid
        let l:command_finished = a:function_to_run(
            \ l:buffer_content,
            \ a:additional_parameter)
    else
        let l:command_finished = a:function_to_run(l:buffer_content)
    endif

    " End the command in case it was finished now.
    if l:command_finished
        call s:ExitCommand()
    endif
endfunction
" s:GetContentAndRun }}}

" s:GetContentFromBuffer {{{
""
" Get the whole content from the buffer as a single string.
" This function gets the line separator in order to support different kinds of
" buffers and file types (for example, Unix VS Windows). It also supports custom
" separator between the lines.
function! s:GetContentFromBuffer(buffer_id, line_separator)
    return join(getbufline(a:buffer_id, 1, "$"), a:line_separator)
endfunction
" s:GetContentFromBuffer }}}

" Buffers }}}

" s:DeleteArgument {{{
""
" Delete the given argument from the system.
" This function will be used for script variables that are being used as context
" between commands, but should not persist in the system for later (in order to
" make sure that they are not being misused).
function! s:DeleteArgument(arg_to_delete)
    execute "unlet " . a:arg_to_delete
endfunction
" s:DeleteArgument }}}

" s:new_line_echom {{{
""
" Echom the message in a new line.
function! s:new_line_echom(message)

    " The only function to clear the command is to run redraw, which would
    " redraw the whole screen. To avoid it and set only this window, run this
    " patch which would remove any message from there.
    normal! :<esc>
    echom a:message

endfunction
" s:new_line_echom }}}

" Vimscript Utils }}}

" Cache {{{

" Update Value in Cache {{{

" s:UpdateValueInCacheListArgumentAdapter {{{
""
" Call the function s:UpdateValueInCache with the proper parameters.
function! s:UpdateValueInCacheListArgumentAdapter(arguments_list)
    return s:UpdateValueInCache(a:arguments_list[0], a:arguments_list[1])
endfunction
" s:UpdateValueInCacheListArgumentAdapter }}}

" s:UpdateValueInCache {{{
""
" Update the given argument in the cache.
" @throws String Error in case the key does not present in the cache.
function! s:UpdateValueInCache(key, value)
    " Validate the key is in the cache.
    if !has_key(s:cache, a:key)
        throw printf("Key '%s' does not exist in the cache", a:key)
    endif

    " Update the key.
    let s:cache[a:key] = a:value
endfunction
" s:UpdateValueInCache }}}

" Update Value in Cache }}}

" s:GetWithCache {{{
""
" Get the needed argument using the cache as hint for the user.
"
" This function will ask the user for the given value. In case the value is
" already in the cache, it will let the user an option to not insert it, and use
" the value from the cache instead.
" After the function will get the new value from the user, it will update the
" cache with this value.
function! s:GetWithCache(key)
    " Get the value
    if s:IsInCache(a:key)
        let l:current_value = s:GetFromCache(a:key)
    else
        let l:current_value = input(printf(s:insert_string_without_default, a:key))
    endif

    " Update the cache.
    let s:cache[a:key] = l:current_value

    " Return the value
    return l:current_value
endfunction
" s:GetWithCache }}}

" s:GetWithCacheAndDefault {{{
""
" Get the needed argument using the cache as hint for the user or the default.
" The value will be added from the cache in case it is there. If it is not in
" the cache, it will be inserted from the defaults.
function! s:GetWithCacheAndDefault(key, default)
    " Get the value
    if s:IsInCache(a:key)
        let l:current_value = s:GetFromCache(a:key)
    else
        let l:current_value = s:GetFromDefault(a:key, a:default)
    endif

    " Update the cache.
    let s:cache[a:key] = l:current_value

    " Return the value
    return l:current_value
endfunction
" s:GetWithCacheAndDefault }}}

" s:GetFromCache {{{
""
" Get the value from the cache, when the value is inside the cache.
function! s:GetFromCache(key)
    if s:plugin.Flag('automatically_insert_cache')
        return s:cache[a:key]
    endif

    return s:InputWithDefault(a:key, s:cache[a:key])
endfunction
" s:GetFromCache }}}

" s:GetFromDefault {{{
""
" Get the value from the cache, when the value is inside the cache.
function! s:GetFromDefault(key, default_value)
    if s:plugin.Flag('automatically_insert_defaults')
        return a:default_value
    endif

    return s:InputWithDefault(a:key, a:default_value)
endfunction
" s:GetFromDefault }}}

" s:InputWithDefault {{{
""
" Get the value for the given value, when there is a default value for the
" wanted information.
" This function will ask the user to insert the value for the key, prompting it
" with a default value from the last time he inserted such value.
function! s:InputWithDefault(key, default)
    let l:current_value = input(printf(
                \ s:insert_string_with_default,
                \ a:key,
                \ a:default))
    if empty(l:current_value)
        return a:default
    endif
    return l:current_value
endfunction
" s:InputWithDefault }}}

" s:VerifyInCache {{{
""
" Verify that all the keys from the list exists in the cache.
" @throws String Error in case one (or more) of the keys are not part of the
"         cache.
function! s:VerifyInCache(keys)
    for l:current_key in a:keys
        if !s:IsInCache(l:current_key)
            throw printf(
                \ "Missing argument in cache. Key '%s' should be in cache.",
                \ l:current_key)
        endif
    endfor
endfunction
" s:VerifyInCache }}}

" s:IsInCache {{{
""
" Return v:true if the given value is inside the cache, v:false otherwise.
function! s:IsInCache(key)
    if empty(s:cache[a:key])
        return v:false
    endif

    return v:true
endfunction
" s:IsInCache }}}

" s:GetWithCacheAndDefaultMethod {{{
""
" Get the value for the given key with the cache and a function that will be
" able to get default argument for this value.
" In case the value will be inside the cache, the function will get it from the
" cache. Otherwise, the function will try to get the default value and use it
" for the value.
function! s:GetWithCacheAndDefaultMethod(key, default_method)
    if s:IsInCache(a:key)
        return s:GetWithCache(a:key)
    endif

    let l:default_value = a:default_method()

    if l:default_value == v:null
        " Continue to call the get with Cache in order to update the cache, even
        " though the key is not there.
        return s:GetWithCache(a:key)
    endif

    " Continue to call the get with Cache in order to update the cache, even
    " though the key is not there.
    return s:GetWithCacheAndDefault(a:key, l:default_value)
endfunction
" s:GetWithCacheAndDefaultMethod }}}
" Cache }}}

" Internal Functions }}}

" Exported Functions {{{

" mr_interface#AddComment {{{
""
" Add a comment to the gitlab MR.
" This function can ran either with no arguments or with all the needed
" arguments for adding a comment.
" In case it is run without arguments, the user will be prompt to add the needed
" arguments. In case it run with all the arguments, the comment will just be
" added to the MR. In case it was run with invalid arguments, an error will be
" printed to the screen.
function! mr_interface#AddComment(...)
    let l:should_finish_command = v:false
    try
        call s:EnterCommand()
        let l:should_finish_command = v:true
        let l:finished = s:RunCommandByNumberOfArguments(
            \ a:000,
            \ {0: function("s:InteractiveAddCommentListArgumentAdapter"),
            \  1: function("s:AddCommentWithBodyListArgumentAdapter"),
            \  3: function("s:AddCommentListArgumentAdapter"),
            \  4: function("s:AddCommentWithPrivateTokenListArgumentAdapter")})
        if !l:finished
            let l:should_finish_command = v:false
        endif
    catch /.*/
        call maktaba#error#Shout(v:exception)
    endtry
    if l:should_finish_command
        call s:ExitCommand()
    endif
endfunction
" mr_interface#AddComment }}}

" mr_interface#AddGeneralDiscussionThread {{{
""
" Add a general discussion thread to the gitlab MR.
" This function can ran either with no arguments or with all the needed
" arguments for adding a comment.
" In case it is run without arguments, the user will be prompt to add the needed
" arguments. In case it run with all the arguments, the discussion thread will
" just be added to the MR. In case it was run with invalid arguments, an error
" will be printed to the screen.
function! mr_interface#AddGeneralDiscussionThread(...)
    let l:should_finish_command = v:false
    try
        call s:EnterCommand()
        let l:should_finish_command = v:true
        let l:finished = s:RunCommandByNumberOfArguments(
            \ a:000,
            \ {0: function("s:InteractiveAddGeneralDiscussionThreadListArgumentAdapter"),
            \  1: function("s:AddGeneralDiscussionThreadWithBodyListArgumentAdapter"),
            \  3: function("s:AddGeneralDiscussionThreadListArgumentAdapter"),
            \  4: function("s:AddGeneralDiscussionThreadWithPrivateTokenListArgumentAdapter")})
        if !l:finished
            let l:should_finish_command = v:false
        endif
    catch /.*/
        call maktaba#error#Shout(v:exception)
    endtry
    if l:should_finish_command
        call s:ExitCommand()
    endif
endfunction
" mr_interface#AddGeneralDiscussionThread }}}

" mr_interface#AddCodeDiscussionThread {{{
""
" Add a code discussion thread to the gitlab MR.
" This function can ran either with no arguments or with all the needed
" arguments for adding a code discussion thread.
" In case it is run without arguments, the user will be prompt to add the needed
" arguments. In case it run with all the arguments, the discussion thread will
" just be added to the MR. In case it was run with invalid number of arguments,
" an error will be printed to the screen.
function! mr_interface#AddCodeDiscussionThread(...)
    let l:should_finish_command = v:false
    try
        call s:EnterCommand()
        let l:should_finish_command = v:true
        let l:finished = s:RunCommandByNumberOfArguments(
            \ a:000,
            \ {0: function("s:InteractiveAddCodeDiscussionThreadListArgumentAdapter"),
            \ 10: function("s:AddCodeDiscussionThreadListArgumentAdapter"),
            \ 11: function("s:AddCodeDiscussionThreadWithPrivateTokenListArgumentAdapter")})
        if !l:finished
            let l:should_finish_command = v:false
        endif
    catch /.*/
        call maktaba#error#Shout(v:exception)
    endtry
    if l:should_finish_command
        call s:ExitCommand()
    endif
endfunction
" mr_interface#AddCodeDiscussionThread }}}

" mr_interface#AddCodeDiscussionThreadOnOldCode {{{
""
" Add a code discussion thread to the gitlab MR.
" This function can ran either with no arguments or with all the needed
" arguments for adding a code discussion thread.
" In case it is run without arguments, the user will be prompt to add the needed
" arguments. In case it run with all the arguments, the discussion thread will
" just be added to the MR. In case it was run with invalid number of arguments,
" an error will be printed to the screen.
function! mr_interface#AddCodeDiscussionThreadOnOldCode(...)
    let l:should_finish_command = v:false
    try
        call s:EnterCommand()
        let l:should_finish_command = v:true
        let l:finished = s:RunCommandByNumberOfArguments(
            \ a:000,
            \ {0: function("s:InteractiveAddCodeDiscussionThreadOnOldCodeListArgumentAdapter"),
            \  1: function("s:AddCodeDiscussionThreadOnOldCodeWithBodyListArgumentAdapter"),
            \  6: function("s:AddCodeDiscussionThreadOnOldCodeListArgumentAdapter"),
            \  7: function("s:AddCodeDiscussionThreadOnOldCodeWithPrivateTokenListArgumentAdapter")})
        if !l:finished
            let l:should_finish_command = v:false
        endif
    catch /.*/
        call maktaba#error#Shout(v:exception)
    endtry
    if l:should_finish_command
        call s:ExitCommand()
    endif
endfunction
" mr_interface#AddCodeDiscussionThreadOnOldCode }}}

" mr_interface#AddCodeDiscussionThreadOnNewCode {{{
""
" Add a code discussion thread to the gitlab MR.
" This function can ran either with no arguments or with all the needed
" arguments for adding a code discussion thread.
" In case it is run without arguments, the user will be prompt to add the needed
" arguments. In case it run with all the arguments, the discussion thread will
" just be added to the MR. In case it was run with invalid number of arguments,
" an error will be printed to the screen.
function! mr_interface#AddCodeDiscussionThreadOnNewCode(...)
    let l:should_finish_command = v:false
    try
        call s:EnterCommand()
        let l:should_finish_command = v:true
        let l:finished = s:RunCommandByNumberOfArguments(
            \ a:000,
            \ {0: function("s:InteractiveAddCodeDiscussionThreadOnNewCodeListArgumentAdapter"),
            \  1: function("s:AddCodeDiscussionThreadOnNewCodeWithBodyListArgumentAdapter"),
            \  6: function("s:AddCodeDiscussionThreadOnNewCodeListArgumentAdapter"),
            \  7: function("s:AddCodeDiscussionThreadOnNewCodeWithPrivateTokenListArgumentAdapter")})
        if !l:finished
            let l:should_finish_command = v:false
        endif
    catch /.*/
        call maktaba#error#Shout(v:exception)
    endtry
    if l:should_finish_command
        call s:ExitCommand()
    endif
endfunction
" mr_interface#AddCodeDiscussionThreadOnNewCode }}}

" mr_interface#ResetCache {{{
""
" Reset the cache of the plugin.
function! mr_interface#ResetCache()
    let l:should_finish_command = v:false
    try
        call s:EnterCommand()
        let l:should_finish_command = v:true
        " This command will map all the currently existing variables of the cache to
        " be empty strings (which are their default values.
        call map(s:cache, '""')
    catch /.*/
        call maktaba#error#Shout(v:exception)
    endtry
    if l:should_finish_command
        call s:ExitCommand()
    endif
endfunction
" mr_interface#ResetCache }}}

" mr_interface#SetCache {{{
""
" Set all the keys in the cache according to the values inserted by the user.
function! mr_interface#SetCache()
    let l:should_finish_command = v:false
    try
        call s:EnterCommand()
        let l:should_finish_command = v:true
        for l:current_key in keys(s:cache)
            call s:GetWithCache(l:current_key)
        endfor
    catch /.*/
        call maktaba#error#Shout(v:exception)
    endtry
    if l:should_finish_command
        call s:ExitCommand()
    endif
endfunction
" mr_interface#SetCache }}}

" mr_interface#UpdateValueInCache {{{
""
" Set the given value in the cache.
" The function gets a key and a value. It sets the value to the key inside the
" cache. In case the key is not a valid key in the cache, an error will be
" printed to the screen.
function! mr_interface#UpdateValueInCache(...)
    let l:should_finish_command = v:false
    try
        call s:EnterCommand()
        let l:should_finish_command = v:true
        call s:RunCommandByNumberOfArguments(
            \ a:000,
            \ {2: function("s:UpdateValueInCacheListArgumentAdapter")})
    catch /.*/
        call maktaba#error#Shout(v:exception)
    endtry
    if l:should_finish_command
        call s:ExitCommand()
    endif
endfunction
" mr_interface#UpdateValueInCache }}}

" Exported Functions }}}

" Functions }}}
