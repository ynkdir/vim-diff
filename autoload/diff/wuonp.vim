"===============================================================================
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
"===============================================================================

" Sun Wu, Udi Manber, Gene Myers and Webb Miller. 1989.
" "An O(NP) Sequence Comparison Algorithm"

function diff#wuonp#import()
  return s:
endfunction

" path[x]
"   = 0   common
"   < 0   delete
"   > 0   add
let s:WuOnpDiff = {}

" @static
function s:WuOnpDiff.diff(A, B)
  return self.new(a:A, a:B).path
endfunction

function s:WuOnpDiff.new(...)
  let obj = deepcopy(self)
  call call(obj.__init__, a:000, obj)
  return obj
endfunction

function s:WuOnpDiff.__init__(A, B)
  if len(a:A) > len(a:B)
    let self.A = a:B
    let self.B = a:A
    let self.M = len(a:B)
    let self.N = len(a:A)
    let self.path = map(self.onp(), '-v:val')
  else
    let self.A = a:A
    let self.B = a:B
    let self.M = len(a:A)
    let self.N = len(a:B)
    let self.path = self.onp()
  endif
endfunction

function s:WuOnpDiff.onp()
  let self.fp = {}
  let self.paths = {}
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
  let path = self.paths[delta]
  " remove garbage
  if !empty(path)
    unlet path[0]
  endif
  return path
endfunction

function s:WuOnpDiff.snake(k)
  let k = a:k

  let i = get(self.fp, k - 1, -1) + 1
  let j = get(self.fp, k + 1, -1)
  if i > j
    if has_key(self.paths, k - 1)
      let self.paths[k] = copy(self.paths[k - 1])
    endif
    let v = 1
  else
    if has_key(self.paths, k + 1)
      let self.paths[k] = copy(self.paths[k + 1])
    endif
    let v = -1
  endif
  if !has_key(self.paths, k)
    let self.paths[k] = []
  endif
  call add(self.paths[k], v)
  let y = max([i, j])

  let x = y - k
  while x < self.M && y < self.N && self.A[x] ==# self.B[y]
    let x += 1
    let y += 1
    call add(self.paths[k], 0)
  endwhile
  return y
endfunction
