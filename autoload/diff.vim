let s:save_cpo = &cpo
set cpo&vim

function diff#diffexpr()
  let old = readfile(v:fname_in, 'b')
  let new = readfile(v:fname_new, 'b')
  let diff = s:DiffOnp.new(old, new)
  let out = diff.format_ed()
  if !empty(out)
    call add(out, '')
  endif
  call writefile(out, v:fname_out, 'b')
endfunction

function diff#ed(old, new)
  let diff = s:DiffOnp.new(a:old, a:new)
  let out = diff.format_ed()
  if !empty(out)
    call add(out, '')
  endif
  return join(out, "\n")
endfunction

" simple version
let s:Diff = {}

function s:Diff.new(...)
  let obj = deepcopy(self)
  call call(obj.__init__, a:000, obj)
  return obj
endfunction

function s:Diff.__init__(A, B)
  let self.A = a:A
  let self.B = a:B
  let self.diffs = self.find_diff()
endfunction

" @return [[oldstart, oldcount, newstart, newcount], ...]
function s:Diff.find_diff()
  let diffs = []
  let todo = [[0, len(self.A), 0, len(self.B)]]
  while !empty(todo)
    let [oldstart, oldend, newstart, newend] = remove(todo, 0)
    let same = self.find_same(oldstart, oldend, newstart, newend)
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

function! s:Diff.find_same(oldstart, oldend, newstart, newend)
  let res = []
  for i in range(a:oldstart, a:oldend - 1)
    let j = index(self.B, self.A[i], a:newstart)
    while j != -1 && j < a:newend
      let k = 1
      while i + k < a:oldend && j + k < a:newend && self.A[i + k] ==# self.B[j + k]
        let k += 1
      endwhile
      if empty(res) || res[2] < k
        let res = [i, j, k]
      endif
      let j = index(self.B, self.A[i], j + 1)
    endwhile
  endfor
  return res
endfunction

function s:Diff.format_ed()
  let base = 1
  let lines = []
  for diff in self.diffs
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
        call add(lines, printf('> %s', self.B[newstart + i]))
      endfor
    elseif newcount == 0
      call add(lines, printf('%sd%s', oldrange, newrange))
      for i in range(oldcount)
        call add(lines, printf('< %s', self.A[oldstart + i]))
      endfor
    else
      call add(lines, printf('%sc%s', oldrange, newrange))
      for i in range(oldcount)
        call add(lines, printf('< %s', self.A[oldstart + i]))
      endfor
      call add(lines, '---')
      for i in range(newcount)
        call add(lines, printf('> %s', self.B[newstart + i]))
      endfor
    endif
  endfor
  return lines
endfunction

"---------------------------------------------------------------------
" G.Myers, W.Miller, An O(NP) Sequence Comparison Algorith
"---------------------------------------------------------------------
" I referred following implementation.
"
" http://ido.nu/kuma/2007/10/01/diff-onp-javascript-implementation/
"
" Copyright (c) 2007, KUMAGAI Kentaro
"
"    Redistribution and use in source and binary forms, with or without
"    modification, are permitted provided that the following conditions
"    are met:
"
" 1. Redistributions of source code must retain the above copyright
"    notice, this list of conditions and the following disclaimer.
" 2. Redistributions in binary form must reproduce the above copyright
"    notice, this list of conditions and the following disclaimer in the
"    documentation and/or other materials provided with the
"    distribution.
" 3. Neither the name of this project nor the names of its contributors
"    may be used to endorse or promote products derived from this
"    software without specific prior written permission.
"
" THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
" "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
" LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
" A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
" OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
" SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
" LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
" DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
" THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
" (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
" OF THIS SO
"---------------------------------------------------------------------

let s:DiffOnp = {}

function s:DiffOnp.new(...)
  let obj = deepcopy(self)
  call call(obj.__init__, a:000, obj)
  return obj
endfunction

function s:DiffOnp.__init__(A, B)
  let self.A = a:A
  let self.B = a:B
  let self.M = len(self.A)
  let self.N = len(self.B)
  if self.M <= self.N
    let self.reverse = 0
  else
    let [self.A, self.B] = [self.B, self.A]
    let [self.M, self.N] = [self.N, self.M]
    let self.reverse = 1
  endif
  let self.fp = {}
  let self.path = {}
  let self.diffs = self.find_diff()
endfunction

function s:DiffOnp.onp()
  let delta = self.N - self.M
  let p = 0
  while 1
    let k = -p
    while k < delta
      let self.fp[k] = self.snake(k)
      let k += 1
    endwhile
    let k = delta + p
    while k > delta
      let self.fp[k] = self.snake(k)
      let k -= 1
    endwhile
    let k = delta
    let self.fp[k] = self.snake(k)
    if self.fp[delta] == self.N
      break
    endif
    let p += 1
  endwhile
  return self.path[delta]
endfunction

function s:DiffOnp.snake(k)
  let k = a:k

  let i = get(self.fp, k - 1, -1) + 1
  let j = get(self.fp, k + 1, -1)
  if i > j
    if has_key(self.path, k - 1)
      let self.path[k] = copy(self.path[k - 1])
    endif
    let v = 1
  else
    if has_key(self.path, k + 1)
      let self.path[k] = copy(self.path[k + 1])
    endif
    let v = -1
  endif
  if !has_key(self.path, k)
    let self.path[k] = []
  endif
  call add(self.path[k], v)
  let y = max([i, j])

  let x = y - k
  while x < self.M && y < self.N && self.A[x] ==# self.B[y]
    let x += 1
    let y += 1
    call add(self.path[k], 0)
  endwhile
  return y
endfunction

function s:DiffOnp.find_diff()
  let path = self.onp()
  let diffs = []
  let x = 0
  let y = 0
  let i = 1
  while i < len(path)
    if path[i] == 0
      let i += 1
      let x += 1
      let y += 1
    elseif path[i] > 0
      let oldstart = y
      let oldcount = 0
      let newstart = x
      let newcount = 0
      while i < len(path) && path[i] > 0
        let newcount += 1
        let i += 1
      endwhile
      while i < len(path) && path[i] < 0
        let oldcount += 1
        let i += 1
      endwhile
      let y += oldcount
      let x += newcount
      call add(diffs, [oldstart, oldcount, newstart, newcount])
    elseif path[i] < 0
      let oldstart = y
      let oldcount = 0
      let newstart = x
      let newcount = 0
      while i < len(path) && path[i] < 0
        let oldcount += 1
        let i += 1
      endwhile
      while i < len(path) && path[i] > 0
        let newcount += 1
        let i += 1
      endwhile
      let y += oldcount
      let x += newcount
      call add(diffs, [oldstart, oldcount, newstart, newcount])
    endif
  endwhile
  return diffs
endfunction

function s:DiffOnp.format_ed()
  let base = 1
  let lines = []
  let old = self.A
  let new = self.B
  if self.reverse
    let [old, new] = [new, old]
  endif
  for diff in self.diffs
    let [oldstart, oldcount, newstart, newcount] = diff
    if self.reverse
      let [oldstart, oldcount, newstart, newcount] = [newstart, newcount, oldstart, oldcount]
    endif
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
        call add(lines, printf('> %s', new[newstart + i]))
      endfor
    elseif newcount == 0
      call add(lines, printf('%sd%s', oldrange, newrange))
      for i in range(oldcount)
        call add(lines, printf('< %s', old[oldstart + i]))
      endfor
    else
      call add(lines, printf('%sc%s', oldrange, newrange))
      for i in range(oldcount)
        call add(lines, printf('< %s', old[oldstart + i]))
      endfor
      call add(lines, '---')
      for i in range(newcount)
        call add(lines, printf('> %s', new[newstart + i]))
      endfor
    endif
  endfor
  return lines
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
