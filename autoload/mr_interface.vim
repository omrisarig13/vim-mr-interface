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
" All the configured arguments.
let s:plugin = maktaba#plugin#Get('vim-mr-interface')

" Constant Global Variables }}}

" Variables }}}

" Functions {{{

" Internal Functions {{{

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

" s:InteractiveAddCodeDiscussionThread {{{
""
" Add a code discussion thread to a gitlab MR interactively.
"
" This functions asks the user to insert all the needed information in order to
" add a code discussion thread, and then adds this new discussion thread to the
" gitlab's MR.
function! s:InteractiveAddCodeDiscussionThread()
    " Get all the comments arguments.
    let l:content = s:InteractiveGetCodeDiscussionThreadContet()
    let l:gitlab_authentication = s:InteractiveGetGitlabAutentication()
    let l:merge_request_information = s:InteractiveGetMergeRequestInformation()

    " Add the comment.
    return s:RunGitlabAction(
        \ l:content,
        \ l:gitlab_authentication,
        \ l:merge_request_information,
        \ s:gitlab_actions.ADD_CODE_DISCUSSION_THREAD)
endfunction
" s:InteractiveAddCodeDiscussionThread }}}

" s:AddCodeDiscussionThread {{{
""
" Add a code discussion thread to a gitlab MR interactively.
function! s:AddCodeDiscussionThread(
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
        \ {'private_token':a:gitlab_private_token},
        \ {'project_id': a:project_id, 'merge_request_id': a:merge_request_id},
        \ s:gitlab_actions.ADD_CODE_DISCUSSION_THREAD)
endfunction
" s:InteractiveAddCodeDiscussionThread }}}

" s:InteractiveGetCodeDiscussionThreadContet {{{
""
" Get all the needed information for the content of a discussion thread on the
" code.
function! s:InteractiveGetCodeDiscussionThreadContet()
    let l:all_variables = {}
    call extend(l:all_variables, s:InteractiveGetBodyAsContent())
    call extend(l:all_variables, s:InteractiveGetPosition())
    return l:all_variables
endfunction
" s:InteractiveGetCodeDiscussionThreadContet }}}

" s:InteractiveGetPosition {{{
""
" Get all the needed information for a position on the code for the MR.
function! s:InteractiveGetPosition()
    let l:base_sha = input("Insert the base sha: ")
    let l:start_sha = input("Insert the start sha: ")
    let l:head_sha = input("Insert the value for the head sha: ")
    let l:old_path = input("Insert the old path of the file: ")
    let l:new_path = input("Insert the new path of the file: ")
    let l:old_line = input("Insert the old line for the comment: ")
    let l:new_line = input("Insert the new line for the comment: ")
    return s:CreatePositionDict(
        \ l:base_sha,
        \ l:start_sha,
        \ l:head_sha,
        \ l:old_path,
        \ l:new_path,
        \ l:old_line,
        \ l:new_line)
endfunction
" s:InteractiveGetPosition }}}

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

" s:InteractiveAddGeneralDiscussionThread {{{
""
" Add a general discussion thread to a gitlab MR interactively.
"
" This functions asks the user to insert all the needed information in order to
" add a comment, and then adds this comment to the gitlab's MR.
function! s:InteractiveAddGeneralDiscussionThread()
    " Get all the comments arguments.
    let l:content = s:InteractiveGetBodyAsContent()
    let l:gitlab_authentication = s:InteractiveGetGitlabAutentication()
    let l:merge_request_information = s:InteractiveGetMergeRequestInformation()

    " Add the comment.
    return s:RunGitlabAction(
        \ l:content,
        \ l:gitlab_authentication,
        \ l:merge_request_information,
        \ s:gitlab_actions.ADD_GENERAL_DISCUSSION_THREAD)
endfunction
" s:InteractiveAddGeneralDiscussionThread }}}

" s:InteractiveGetBodyAsContent {{{
""
" Get the body of the gitlab action in the needed format as content.
" This function should be used for commands that all their content is just the
" 'body' of the command. Such commands are ADD_GENERAL_DISCUSSION_THREAD or
" ADD_COMMENT.
" This function will read the string from the user and set it as return it in
" the needed format for the content adding.
function! s:InteractiveGetBodyAsContent()
    let l:body = input("Insert discussion thread body: ")
    return {"body" : l:body}
endfunction
" s:InteractiveGetBodyAsContent }}}

" s:InteractiveGetMergeRequestInformation {{{
""
" Get all the needed information to add something into a merge request.
function! s:InteractiveGetMergeRequestInformation()
    let l:project_id = input("Insert project id: ")
    let l:merge_request_id = input("Insert merge request id: ")

    return {'project_id': l:project_id, 'merge_request_id': l:merge_request_id}
endfunction
" s:InteractiveGetMergeRequestInformation }}}

" s:InteractiveGetGitlabAutentication {{{
""
" Get all the needed information to authenticate with the gitlab interactively.
"
" Currently, it just asks the user to insert his private token. However, it can
" be changed in the future, for more secure authentication.
function! s:InteractiveGetGitlabAutentication()
    let l:private_token = input("Insert gitlab private token: ")

    return {'private_token': l:private_token}
endfunction
" s:InteractiveGetGitlabAutentication }}}h

" s:AddGeneralDiscussionThread {{{
""
" Add the given comment into the given gitlab's MR.
function! s:AddGeneralDiscussionThread(
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
" s:AddGeneralDiscussionThread }}}

" s:InteractiveAddComment {{{
""
" Add a comment to a gitlab MR interactively.
"
" This functions asks the user to insert all the needed information in order to
" add a comment, and then adds this comment to the gitlab's MR.
function! s:InteractiveAddComment()
    " Get all the comments arguments.
    let l:content = s:InteractiveGetBodyAsContent()
    let l:gitlab_authentication = s:InteractiveGetGitlabAutentication()
    let l:merge_request_information = s:InteractiveGetMergeRequestInformation()

    " Add the comment.
    return s:RunGitlabAction(
        \ l:content,
        \ l:gitlab_authentication,
        \ l:merge_request_information,
        \ s:gitlab_actions.ADD_COMMENT)
endfunction
" s:InteractiveAddComment }}}

" s:AddComment {{{
""
" Add the given comment into the given gitlab's MR.
function! s:AddComment(
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
" s:AddComment }}}

" s:RunGitlabAction {{{
""
" Add the given comment into the given gitlab's MR.
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
endfunction
" s:RunGitlabAction }}}

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
    " TODO: Get the address of gitlab as well (for other gitlabs).
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
    " Get the real arguments.
    let l:real_arguments = s:GetArgumentsFromCommandLine(a:000)

    " Call the actual function.
    if len(l:real_arguments) == 0
        call s:InteractiveAddComment()
    elseif len(l:real_arguments) == 4
        " TODO: I could not find a way to unpack the list automatically. Try to
        " research it a bit more in the future.
        call s:AddComment(
            \ l:real_arguments[0],
            \ l:real_arguments[1],
            \ l:real_arguments[2],
            \ l:real_arguments[3])
    else
        call maktaba#error#Shout(
            \ "Invalid number of arguments to add command")
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
"
" This function looks a lot like the function mr_interface#AddComment. However,
" they should not be merged into a single action. These actions depend on
" different interfaces of gitlab. Since these interfaces can be changed
" differently, these commands won't look the same, and the functions will have
" to change. It is better to keep these commands separated.
function! mr_interface#AddGeneralDiscussionThread(...)
    " Get the real arguments.
    let l:real_arguments = s:GetArgumentsFromCommandLine(a:000)

    " Call the actual function.
    if len(l:real_arguments) == 0
        call s:InteractiveAddGeneralDiscussionThread()
    elseif len(l:real_arguments) == 4
        " TODO: I could not find a way to unpack the list automatically. Try to
        " research it a bit more in the future.
        call s:AddGeneralDiscussionThread(
            \ l:real_arguments[0],
            \ l:real_arguments[1],
            \ l:real_arguments[2],
            \ l:real_arguments[3])
    else
        call maktaba#error#Shout(
            \ "Invalid number of arguments to add command")
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
"
" This function looks a lot like the function mr_interface#AddComment. However,
" they should not be merged into a single action. These actions depend on
" different interfaces of gitlab. Since these interfaces can be changed
" differently, these commands won't look the same, and the functions will have
" to change. It is better to keep these commands separated.
function! mr_interface#AddCodeDiscussionThread(...)
    " Get the real arguments.
    let l:real_arguments = s:GetArgumentsFromCommandLine(a:000)

    " Call the actual function.
    if len(l:real_arguments) == 0
        call s:InteractiveAddCodeDiscussionThread()
    elseif len(l:real_arguments) == 11
        " TODO: I could not find a way to unpack the list automatically. Try to
        " research it a bit more in the future.
        call s:AddCodeDiscussionThread(
            \ l:real_arguments[0],
            \ l:real_arguments[1],
            \ l:real_arguments[2],
            \ l:real_arguments[3],
            \ l:real_arguments[4],
            \ l:real_arguments[5],
            \ l:real_arguments[6],
            \ l:real_arguments[7],
            \ l:real_arguments[8],
            \ l:real_arguments[9],
            \ l:real_arguments[10])
    else
        call maktaba#error#Shout(
            \ "Invalid number of arguments to add code discussion thread command")
    endif
endfunction
" mr_interface#AddCodeDiscussionThread }}}

" Exported Functions }}}

" Functions }}}
