let s:save_cpo = &cpo
set cpo&vim

function diff#diffexpr()
  call diff#fnormal(v:fname_in, v:fname_new, v:fname_out)
endfunction

function diff#normal(old, new)
  let diff = s:DiffOnp.new(a:old, a:new)
  let out = diff.format_normal()
  return out
endfunction

function diff#bnormal(old, new)
  let options = {}
  let A = copy(a:old)
  if !empty(A) && A[-1] == ''
    let options.Aeol = 1
    unlet A[-1]
  else
    let options.Aeol = 0
  endif
  let B = copy(a:new)
  if !empty(B) && B[-1] == ''
    let options.Beol = 1
    unlet B[-1]
  else
    let options.Beol = 0
  endif
  let diff = s:DiffOnp.new(A, B, options)
  let out = diff.format_normal()
  return out
endfunction

function diff#fnormal(oldfile, newfile, outfile)
  let old = readfile(a:oldfile, 'b')
  let new = readfile(a:newfile, 'b')
  let out = diff#bnormal(old, new)
  if !empty(out)
    call add(out, '')
  endif
  call writefile(out, a:outfile, 'b')
endfunction

let s:NOEOL = '\ No newline at end of file'

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

function s:DiffOnp.__init__(A, B, ...)
  let options_default = {'Aeol': 1, 'Beol': 1}
  let options = extend(options_default, get(a:000, 0, {}))
  if len(a:A) > len(a:B)
    let self.A = a:B
    let self.B = a:A
    let self.M = len(a:B)
    let self.N = len(a:A)
    let self.Aeol = options.Beol
    let self.Beol = options.Aeol
    let self.reverse = 1
  else
    let self.A = a:A
    let self.B = a:B
    let self.M = len(a:A)
    let self.N = len(a:B)
    let self.Aeol = options.Aeol
    let self.Beol = options.Beol
    let self.reverse = 0
  endif
  " Add \n to detect noeol.
  let A = map(copy(self.A), 'v:val . "\n"')
  if !empty(A) && !self.Aeol
    let A[-1] = self.A[-1]
  endif
  let B = map(copy(self.B), 'v:val . "\n"')
  if !empty(B) && !self.Beol
    let B[-1] = self.B[-1]
  endif
  let self.Acmp = self.makecmpbuf(A)
  let self.Bcmp = self.makecmpbuf(B)
  let self.fp = {}
  let self.path = {}
  let self.diffs = self.find_diff()
endfunction

" TODO: ignorecase, whitespace, etc...
function s:DiffOnp.makecmpbuf(lines)
  return a:lines
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
  while x < self.M && y < self.N && self.Acmp[x] ==# self.Bcmp[y]
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

function s:DiffOnp.format_normal()
  let base = 1
  let lines = []
  if self.reverse
    let old = self.B
    let new = self.A
    let oldeol = self.Beol
    let neweol = self.Aeol
  else
    let old = self.A
    let new = self.B
    let oldeol = self.Aeol
    let neweol = self.Beol
  endif
  for diff in self.diffs
    if self.reverse
      let [newstart, newcount, oldstart, oldcount] = diff
    else
      let [oldstart, oldcount, newstart, newcount] = diff
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
      if !neweol && newstart + newcount == len(new)
        call add(lines, s:NOEOL)
      endif
    elseif newcount == 0
      call add(lines, printf('%sd%s', oldrange, newrange))
      for i in range(oldcount)
        call add(lines, printf('< %s', old[oldstart + i]))
      endfor
      if !oldeol && oldstart + oldcount == len(old)
        call add(lines, s:NOEOL)
      endif
    else
      call add(lines, printf('%sc%s', oldrange, newrange))
      for i in range(oldcount)
        call add(lines, printf('< %s', old[oldstart + i]))
      endfor
      if !oldeol && oldstart + oldcount == len(old)
        call add(lines, s:NOEOL)
      endif
      call add(lines, '---')
      for i in range(newcount)
        call add(lines, printf('> %s', new[newstart + i]))
      endfor
      if !neweol && newstart + newcount == len(new)
        call add(lines, s:NOEOL)
      endif
    endif
  endfor
  return lines
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
