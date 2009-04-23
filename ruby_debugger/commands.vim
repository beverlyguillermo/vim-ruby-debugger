" *** RubyDebugger Commands *** 


" <breakpoint file="test.rb" line="1" threadId="1" />
function! RubyDebugger.commands.jump_to_breakpoint(cmd) dict
  let attrs = s:get_tag_attributes(a:cmd) 
  call s:jump_to_file(attrs.file, attrs.line)
  call g:RubyDebugger.logger.put("Jumped to breakpoint " . attrs.file . ":" . attrs.line)
  call s:send_message_to_debugger('var local')
endfunction


" <breakpointAdded no="1" location="test.rb:2" />
function! RubyDebugger.commands.set_breakpoint(cmd)
  let attrs = s:get_tag_attributes(a:cmd)
  let file_match = matchlist(attrs.location, '\(.*\):\(.*\)')
  " Set pid of current debugger to current breakpoint
  let pid = g:RubyDebugger.server.rdebug_pid

  for breakpoint in g:RubyDebugger.breakpoints
    if expand(breakpoint.file) == expand(file_match[1]) && expand(breakpoint.line) == expand(file_match[2])
      let breakpoint.debugger_id = attrs.no
      let breakpoint.rdebug_pid = pid
    endif
  endfor

  call g:RubyDebugger.logger.put("Breakpoint is set: " . file_match[1] . ":" . file_match[2])

  let not_assigned_breakpoints = filter(copy(g:RubyDebugger.breakpoints), '!has_key(v:val, "rdebug_pid") || v:val["rdebug_pid"] != ' . pid)
  let not_assigned_breakpoint = get(not_assigned_breakpoints, 0)
  if type(not_assigned_breakpoint) == type({})
    call not_assigned_breakpoint.send_to_debugger()
  endif
endfunction


" <variables>
"   <variable name="array" kind="local" value="Array (2 element(s))" type="Array" hasChildren="true" objectId="-0x2418a904"/>
" </variables>
function! RubyDebugger.commands.set_variables(cmd)
  let tags = s:get_tags(a:cmd)
  let list_of_variables = []
  for tag in tags
    let attrs = s:get_tag_attributes(tag)
    let variable = s:Var.new(attrs)
    call add(list_of_variables, variable)
  endfor
  if g:RubyDebugger.variables == {}
    let g:RubyDebugger.variables = s:VarParent.new({'hasChildren': 'true'})
    let g:RubyDebugger.variables.is_open = 1
    let g:RubyDebugger.variables.children = []
  endif
  if has_key(g:RubyDebugger, 'current_variable')
    let variable_name = g:RubyDebugger.current_variable
    call g:RubyDebugger.logger.put("Trying to find variable: " . variable_name)
    let variable = g:RubyDebugger.variables.find_variable({'name': variable_name})
    unlet g:RubyDebugger.current_variable
    if variable != {}
      call g:RubyDebugger.logger.put("Found variable: " . variable_name)
      call variable.add_childs(list_of_variables)
      let s:variables_window.data = g:RubyDebugger.variables
      call g:RubyDebugger.logger.put("Opening child variable: " . variable_name)
      call s:variables_window.open()
    else
      call g:RubyDebugger.logger.put("Can't found variable with name: " . variable_name)
    endif
  else
    if g:RubyDebugger.variables.children == []
      call g:RubyDebugger.variables.add_childs(list_of_variables)
      let s:variables_window.data = g:RubyDebugger.variables
      call g:RubyDebugger.logger.put("Initializing local variables")
    endif
  endif
endfunction

" *** End of debugger Commands ***



