" diff.vim
" usage:
"   :set runtimepath+=/path/to/vim-diff
"   :set diffexpr=diff#diffexpr()

let s:save_cpo = &cpo
set cpo&vim

function diff#diffexpr()
  let old = readfile(v:fname_in)
  let new = readfile(v:fname_new)
  let diff = s:Diff.new()
  if 0
    let [oldid, newid] = diff.makeid(old, new)
    let diffs = diff.find_diff(oldid, newid)
  else
    let diffs = diff.find_diff(old, new)
  endif
  let out = diff.format_ed(old, new, diffs)
  call writefile(out, v:fname_out)
endfunction

function diff#ed(old, new)
  let diff = s:Diff.new()
  let diffs = diff.find_diff(a:old, a:new)
  return diff.format_ed(a:old, a:new, diffs)
endfunction

let s:Diff = {}

function s:Diff.new(...)
  let obj = deepcopy(self)
  call call(obj.__init__, a:000, obj)
  return obj
endfunction

function s:Diff.__init__()
endfunction

function s:Diff.makeid(old, new)
  let nextid = 1    " 0 for empty
  let ids = {}
  let old = repeat([0], len(a:old))
  for i in range(len(old))
    let id = a:old[i] == '' ? 0 : get(ids, a:old[i], -1)
    if id == -1
      let ids[a:old[i]] = nextid
      let nextid += 1
    endif
    let old[i] = id
  endfor
  let new = repeat([0], len(a:new))
  for i in range(len(new))
    let id = a:new[i] == '' ? 0 : get(ids, a:new[i], -1)
    if id == -1
      let ids[a:new[i]] = nextid
      let nextid += 1
    endif
    let new[i] = id
  endfor
  return [old, new]
endfunction

" @return [[oldstart, oldcount, newstart, newcount], ...]
function s:Diff.find_diff(old, new)
  let diffs = []
  let todo = [[0, len(a:old), 0, len(a:new)]]
  while !empty(todo)
    let [oldstart, oldend, newstart, newend] = remove(todo, 0)
    let same = self.find_same(a:old, oldstart, oldend, a:new, newstart, newend)
    if empty(same)
      call add(diffs, [oldstart, oldend - oldstart, newstart, newend - newstart])
    else
      let [oldsamestart, newsamestart, cnt] = same
      let oldsameend = oldsamestart + cnt
      let newsameend = newsamestart + cnt
      if oldsamestart == oldstart
        if newsamestart != newstart
          call add(diffs, [oldstart, 0, newstart, newsamestart - newstart])
        endif
      else
        if newsamestart == newstart
          call add(diffs, [oldstart, oldsamestart - oldstart, newstart, 0])
        else
          call add(todo, [oldstart, oldsamestart, newstart, newsamestart])
        endif
      endif
      if oldsameend == oldend
        if newsameend != newend
          call add(diffs, [oldend, 0, newsameend, newend - newsameend])
        endif
      else
        if newsameend == newend
          call add(diffs, [oldsameend, oldend - oldsameend, newend, 0])
        else
          call add(todo, [oldsameend, oldend, newsameend, newend])
        endif
      endif
    endif
  endwhile
  return sort(diffs, self.diffsort, self)
endfunction

function s:Diff.diffsort(a, b)
  return a:a[0] == a:b[0] ? 0 : a:a[0] > a:b[0] ? 1 : -1
endfunction

" Find longest same part.
" @return [old-lnum, new-lnum, count] or []
function s:Diff.find_same(old, oldstart, oldend, new, newstart, newend)
  let res = []
  for i in range(a:oldstart, a:oldend - 1)
    for j in range(a:newstart, a:newend - 1)
      if a:old[i] ==# a:new[j]
        let k = 1
        while i + k < a:oldend && j + k < a:newend && a:old[i + k] ==# a:new[j + k]
          let k += 1
        endwhile
        if empty(res) || res[2] < k
          let res = [i, j, k]
        endif
      endif
    endfor
  endfor
  return res
endfunction

" fast version
function! s:Diff.find_same(old, oldstart, oldend, new, newstart, newend)
  let res = []
  for i in range(a:oldstart, a:oldend - 1)
    let j = index(a:new, a:old[i], a:newstart)
    while j != -1 && j < a:newend
      let k = 1
      while i + k < a:oldend && j + k < a:newend && a:old[i + k] ==# a:new[j + k]
        let k += 1
      endwhile
      if empty(res) || res[2] < k
        let res = [i, j, k]
      endif
      let j = index(a:new, a:old[i], j + 1)
    endwhile
  endfor
  return res
endfunction

function s:Diff.format_ed(old, new, diffs)
  let base = 1
  let lines = []
  for diff in a:diffs
    let [oldstart, oldcount, newstart, newcount] = diff
    if oldcount == 0
      let oldrange = printf('%d', oldstart)
    elseif oldcount == 1
      let oldrange = printf('%d', oldstart + base)
    else
      let oldrange = printf('%d,%d', oldstart + base, oldstart + base + oldcount - 1)
    endif
    if newcount == 0
      let newrange = printf('%d', newstart)
    elseif newcount == 1
      let newrange = printf('%d', newstart + base)
    else
      let newrange = printf('%d,%d', newstart + base, newstart + base + newcount - 1)
    endif
    if oldcount == 0
      call add(lines, printf('%sa%s', oldrange, newrange))
      for i in range(newcount)
        call add(lines, printf('> %s', a:new[newstart + i]))
      endfor
    elseif newcount == 0
      call add(lines, printf('%sd%s', oldrange, newrange))
      for i in range(oldcount)
        call add(lines, printf('< %s', a:old[oldstart + i]))
      endfor
    else
      call add(lines, printf('%sc%s', oldrange, newrange))
      for i in range(oldcount)
        call add(lines, printf('< %s', a:old[oldstart + i]))
      endfor
      call add(lines, '---')
      for i in range(newcount)
        call add(lines, printf('> %s', a:new[newstart + i]))
      endfor
    endif
  endfor
  return lines
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
