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

" s:InteractiveAddComment {{{
""
" Add a comment to a gitlab MR interactively.
"
" This functions asks the user to insert all the needed information in order to
" add a comment, and then adds this comment to the gitlab's MR.
function! s:InteractiveAddComment()
    " Get all the comments arguments.
    let l:comment_body = input("Insert comment body: ")
    let l:gitlab_private_token = input("Insert gitlab private token: ")
    let l:project_id = input("Insert project id: ")
    let l:merge_request_id = input("Insert merge request id: ")

    " Add the comment.
    return s:AddComment(
        \ l:comment_body,
        \ l:gitlab_private_token,
        \ l:project_id,
        \ l:merge_request_id)
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
    " Create the command.
    let l:command = s:CreateMRAddCommentCommand(
        \ a:comment_body,
        \ a:gitlab_private_token,
        \ a:project_id,
        \ a:merge_request_id)

    " Run the command.
    let l:command_result = system(l:command)

    " Check (and print message) about the command's result.
    call s:ValidateCommandOutput(
        \ l:command_result,
        \ "Added comment successfully",
        \ "Could not add comment. Error: ")
endfunction
" s:AddComment }}}

" s:CreateMRAddCommentCommand {{{
""
" Creates the needed command in order to add the comment to the given MR.
function! s:CreateMRAddCommentCommand(
            \ comment_body,
            \ gitlab_private_token,
            \ project_id,
            \ merge_request_id)
    let l:url = s:CreateGitlabCommentAddAddress(
        \ a:project_id,
        \ a:merge_request_id)
    return printf(
        \ 'curl -d "body=%s" --request POST --header "PRIVATE-TOKEN: %s" %s',
        \ a:comment_body,
        \ a:gitlab_private_token,
        \ l:url)
endfunction
" s:CreateMRAddCommentCommand }}}

" s:CreateGitlabCommentAddAddress {{{
""
" Create the needed command in order to add a comment to the given gitlab MR.
function! s:CreateGitlabCommentAddAddress(project_id, merge_request_id)
    " TODO: Get the address of gitlab as well (for other gitlabs).
    return printf(
        \ "https://gitlab.com/api/v4/projects/%s/merge_requests/%s/notes?body=note",
        \ a:project_id,
        \ a:merge_request_id)
endfunction!
" s:CreateGitlabCommentAddAddress }}}

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

" Exported Functions }}}

" Functions }}}
